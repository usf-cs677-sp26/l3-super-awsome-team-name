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
	"strings"
)

func put(msgHandler *messages.MessageHandler, fileName string) int {
	fmt.Println("PUT", fileName)

	// Get file size and make sure it exists
	info, err := os.Stat(fileName)
	if err != nil {
		log.Fatalln("File not found:", err)
	}

	// Extract just the filename to send to server
	fileNameOnly := filepath.Base(fileName)

	// Tell the server we want to store this file
	msgHandler.SendStorageRequest(fileNameOnly, uint64(info.Size()))
	ok, msg := msgHandler.ReceiveResponse()
	if !ok {
		log.Println("Server rejected storage request:", msg)
		return 1
	}

	file, err := os.Open(fileName)
	if err != nil {
		log.Fatalln("Failed to open file:", err)
	}
	md5 := md5.New()
	w := io.MultiWriter(msgHandler, md5)
	io.CopyN(w, file, info.Size()) // Checksum and transfer file at same time
	file.Close()

	checksum := md5.Sum(nil)
	msgHandler.SendChecksumVerification(checksum)
	ok, msg = msgHandler.ReceiveResponse()
	if !ok {
		log.Println("Storage failed:", msg)
		return 1
	}

	fmt.Println("Storage complete!")
	return 0
}

func get(msgHandler *messages.MessageHandler, fileName string, destDir string) int {
	fmt.Println("GET", fileName)

	// Extract just the filename to request from server
	fileNameOnly := filepath.Base(fileName)

	// Change to destination directory if specified
	if destDir != "." {
		if err := os.Chdir(destDir); err != nil {
			log.Fatalln("Failed to change to destination directory:", err)
		}
	}

	msgHandler.SendRetrievalRequest(fileNameOnly)
	ok, msg, size := msgHandler.ReceiveRetrievalResponse()
	if !ok {
		log.Println("Server rejected retrieval request:", msg)
		return 1
	}

	// Create file in current directory (which is now destDir if specified)
	file, err := os.OpenFile(fileNameOnly, os.O_CREATE|os.O_EXCL|os.O_WRONLY, 0666)
	if err != nil {
		log.Println("Failed to create file:", err)
		return 1
	}

	md5 := md5.New()
	w := io.MultiWriter(file, md5)
	io.CopyN(w, msgHandler, int64(size))
	file.Close()

	clientCheck := md5.Sum(nil)
	checkMsg, err := msgHandler.Receive()
	if err != nil {
		log.Println("Failed to receive checksum:", err)
		return 1
	}
	serverCheck := checkMsg.GetChecksum().Checksum

	if util.VerifyChecksum(serverCheck, clientCheck) {
		log.Println("Successfully retrieved file.")
	} else {
		log.Println("FAILED to retrieve file. Invalid checksum.")
		return 1
	}

	return 0
}

func main() {
	if len(os.Args) < 4 {
		fmt.Printf("Not enough arguments. Usage: %s server:port put|get file-name [download-dir]\n", os.Args[0])
		os.Exit(1)
	}

	host := os.Args[1]
	conn, err := net.Dial("tcp", host)
	if err != nil {
		log.Fatalln(err.Error())
		return
	}
	msgHandler := messages.NewMessageHandler(conn)
	defer conn.Close()

	action := strings.ToLower(os.Args[2])
	if action != "put" && action != "get" {
		log.Fatalln("Invalid action", action)
	}

	fileName := os.Args[3]

	dir := "."
	if len(os.Args) >= 5 {
		dir = os.Args[4]
	}

	if action == "put" {
		os.Exit(put(msgHandler, fileName))
	} else if action == "get" {
		os.Exit(get(msgHandler, fileName, dir))
	}
}
