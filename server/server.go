package main

import (
	"crypto/md5"
	"file-transfer/messages"
	"file-transfer/util"
	"fmt"
	"io"
	"log"
	"net"
	"os"
	"path/filepath"
)

func handleStorage(msgHandler *messages.MessageHandler, request *messages.StorageRequest) {
	// Extract just the filename from the path
	fileName := filepath.Base(request.FileName)
	log.Println("Attempting to store", fileName)

	// Check if file already exists
	if _, err := os.Stat(fileName); err == nil {
		msgHandler.SendResponse(false, "File already exists")
		msgHandler.Close()
		return
	}

	// Try to create the file (will fail if exists due to O_EXCL, or if disk space issues)
	file, err := os.OpenFile(fileName, os.O_CREATE|os.O_EXCL|os.O_WRONLY, 0666)
	if err != nil {
		msgHandler.SendResponse(false, err.Error())
		msgHandler.Close()
		return
	}

	msgHandler.SendResponse(true, "Ready for data")
	md5 := md5.New()
	w := io.MultiWriter(file, md5)
	io.CopyN(w, msgHandler, int64(request.Size)) /* Write and checksum as we go */
	file.Close()

	serverCheck := md5.Sum(nil)

	clientCheckMsg, err := msgHandler.Receive()
	if err != nil {
		msgHandler.SendResponse(false, "Failed to receive checksum")
		msgHandler.Close()
		return
	}
	clientCheck := clientCheckMsg.GetChecksum().Checksum

	if util.VerifyChecksum(serverCheck, clientCheck) {
		log.Println("Successfully stored file.")
		msgHandler.SendResponse(true, "File stored successfully")
	} else {
		log.Println("FAILED to store file. Invalid checksum.")
		os.Remove(fileName) // Remove the file if checksum doesn't match
		msgHandler.SendResponse(false, "Checksum verification failed")
	}
}

func handleRetrieval(msgHandler *messages.MessageHandler, request *messages.RetrievalRequest) {
	// Extract just the filename from the path
	fileName := filepath.Base(request.FileName)
	log.Println("Attempting to retrieve", fileName)

	// Get file size and make sure it exists
	info, err := os.Stat(fileName)
	if err != nil {
		if os.IsNotExist(err) {
			msgHandler.SendRetrievalResponse(false, "File does not exist", 0)
		} else {
			msgHandler.SendRetrievalResponse(false, err.Error(), 0)
		}
		msgHandler.Close()
		return
	}

	msgHandler.SendRetrievalResponse(true, "Ready to send", uint64(info.Size()))

	file, err := os.Open(fileName)
	if err != nil {
		msgHandler.Close()
		return
	}
	md5 := md5.New()
	w := io.MultiWriter(msgHandler, md5)
	io.CopyN(w, file, info.Size()) // Checksum and transfer file at same time
	file.Close()

	checksum := md5.Sum(nil)
	msgHandler.SendChecksumVerification(checksum)
}

func handleClient(msgHandler *messages.MessageHandler) {
	defer msgHandler.Close()

	for {
		wrapper, err := msgHandler.Receive()
		if err != nil {
			log.Println(err)
		}

		switch msg := wrapper.Msg.(type) {
		case *messages.Wrapper_StorageReq:
			handleStorage(msgHandler, msg.StorageReq)
			continue
		case *messages.Wrapper_RetrievalReq:
			handleRetrieval(msgHandler, msg.RetrievalReq)
			continue
		case nil:
			log.Println("Received an empty message, terminating client")
			return
		default:
			log.Printf("Unexpected message type: %T", msg)
		}
	}
}

func main() {
	if len(os.Args) < 2 {
		fmt.Printf("Not enough arguments. Usage: %s port [download-dir]\n", os.Args[0])
		os.Exit(1)
	}

	port := os.Args[1]
	listener, err := net.Listen("tcp", ":"+port)
	if err != nil {
		log.Fatalln(err.Error())
		os.Exit(1)
	}
	defer listener.Close()

	dir := "."
	if len(os.Args) >= 3 {
		dir = os.Args[2]
	}

	// Ensure the storage directory exists
	if err := os.MkdirAll(dir, 0755); err != nil {
		log.Fatalln("Failed to create storage directory:", err)
	}

	if err := os.Chdir(dir); err != nil {
		log.Fatalln("Failed to change to storage directory:", err)
	}

	fmt.Println("Listening on port:", port)
	fmt.Println("Download directory:", dir)
	for {
		if conn, err := listener.Accept(); err == nil {
			log.Println("Accepted connection", conn.RemoteAddr())
			handler := messages.NewMessageHandler(conn)
			go handleClient(handler)
		}
	}
}
