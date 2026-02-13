# Testing Guide - Minimal File Transfer System

## Quick Start Instructions

### On Machine 1 (e.g., mc07) - Server Setup

1. **Build the project:**
   ```bash
   make clean
   make all
   ```

2. **Regenerate protobuf files** (if you modified proto/messages.proto):
   ```bash
   cd proto
   bash build.sh
   cd ..
   make all
   ```

3. **Start the server:**
   ```bash
   ./bin/server 9898 ./storage
   ```
   The server will listen on port 9898 and store files in `./storage` directory.

### On Machine 2 (e.g., mc08) - Client Testing

1. **Build the project** (same steps as above)

2. **Test PUT operation** (store a file):
   ```bash
   ./bin/client mc07:9898 put /path/to/your/testfile.txt
   ```
   Note: The client can send a full path, but the server will store just the filename.

3. **Test GET operation** (retrieve a file):
   ```bash
   ./bin/client mc07:9898 get testfile.txt ./downloads
   ```
   This will download `testfile.txt` from the server to `./downloads/testfile.txt`

### Testing Scenarios

1. **Basic PUT and GET:**
   - PUT a small text file
   - GET the same file
   - Verify checksums match

2. **Test with different file types:**
   - Text files (.txt)
   - Binary files (.jpg, .pdf, etc.)
   - Large files (to test performance)

3. **Error cases:**
   - Try to PUT the same file twice (should fail - file exists)
   - Try to GET a non-existent file (should fail)
   - Try to GET to a non-existent directory (should fail)

4. **Cross-machine testing:**
   - Server on mc07, client on mc08
   - Server on mc08, client on mc07
   - Test both directions

## Key Features Implemented

✅ **Server:**
- Listens on specified port
- Handles multiple clients with goroutines
- Extracts filename from path (stores just filename, not full path)
- Refuses to overwrite existing files
- Creates storage directory if it doesn't exist
- Verifies checksums after file transfer
- Sends final response after checksum verification

✅ **Client:**
- Connects to server
- PUT: Sends file with checksum, waits for verification
- GET: Receives file, verifies checksum
- Extracts filename from path for server communication
- Handles destination directory for GET operations

## Protocol Flow

### PUT Operation:
1. Client sends `StorageRequest` (filename, size)
2. Server checks if file exists, responds OK/FAIL
3. If OK, client sends file data (raw bytes)
4. Client sends checksum
5. Server verifies checksum, sends final response

### GET Operation:
1. Client sends `RetrievalRequest` (filename)
2. Server checks if file exists, responds with size or error
3. If OK, server sends file data (raw bytes)
4. Server sends checksum
5. Client verifies checksum

## Troubleshooting

- **Connection refused:** Check firewall, ensure server is running, verify hostname/port
- **File not found:** Make sure you're using the correct filename (server stores just the base filename)
- **Checksum mismatch:** Usually indicates network corruption or transfer error
- **Permission denied:** Check directory permissions on both machines

