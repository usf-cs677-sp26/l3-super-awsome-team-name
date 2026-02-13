# File Transfer Client and Server

A minimal file transfer system implementing PUT and GET operations using TCP and Protocol Buffers.

## Features

- **PUT Operation**: Store files on the server with checksum verification
- **GET Operation**: Retrieve files from the server with checksum verification
- **Error Handling**: Proper handling of file existence, disk space, and network errors
- **Multi-client Support**: Server handles multiple concurrent connections using goroutines

## Usage

### Server
```bash
./bin/server listen-port [download-dir]
# Example: ./bin/server 9898 ./storage
```

### Client
```bash
./bin/client host:port put|get file-name [destination-dir]
# Example PUT: ./bin/client localhost:9898 put /some/file.jpg
# Example GET: ./bin/client localhost:9898 get file.jpg ./downloads
```

## Building

```bash
# Regenerate protobuf files
cd proto
bash build.sh
cd ..

# Build binaries
make clean
make all
```

## Protocol

- **Control Plane**: Protocol Buffers for metadata (operation types, file names, sizes, checksums)
- **Data Plane**: Raw bytes over TCP for file data transfer
- **Checksums**: MD5 for file integrity verification

## Compatibility Notes

This implementation uses the protocol defined in `proto/messages.proto`. For compatibility with other implementations, ensure the `.proto` file matches exactly.

### Protocol Buffer Messages
- `StorageRequest`: File name and size
- `RetrievalRequest`: File name
- `RetrievalResponse`: Response status, file size
- `Response`: OK status and message
- `ChecksumVerification`: MD5 checksum bytes
- `Wrapper`: Oneof container for all message types

## Testing

See `TESTING_GUIDE.md` for detailed testing instructions.

## Changes for Compatibility

_No compatibility changes made yet. This section will be updated after testing with teammates._
