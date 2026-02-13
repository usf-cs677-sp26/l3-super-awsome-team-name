# Build Notes

## Important: Regenerate Protocol Buffer Files

After modifying `proto/messages.proto`, you **must** regenerate the Go code:

```bash
cd proto
bash build.sh
```

Or if you have `protoc` installed:

```bash
cd proto
protoc --go_out=../messages --go_opt=paths=source_relative messages.proto
```

## Compilation

After regenerating protobuf files:

```bash
make clean
make all
```

## Testing the System

1. **Build the project:**
   ```bash
   make all
   ```

2. **Regenerate protobuf files** (if not done already):
   ```bash
   cd proto && bash build.sh
   ```

3. **Start the server** (on one machine):
   ```bash
   ./bin/server 9898 ./storage
   ```

4. **Test file operations** (from another machine or same machine):
   ```bash
   # Store a file
   ./bin/client localhost:9898 put /path/to/file.txt
   
   # Retrieve a file
   ./bin/client localhost:9898 get file.txt ./downloads
   ```

## Usage

**Server:**
```bash
./server listen-port [download-dir]
# Example: ./server 9898 ./stuff/
```

**Client:**
```bash
./client host:port put|get file-name [destination-dir]
# Example PUT: ./client localhost:9898 put /some/file.jpg
# Example GET: ./client localhost:9898 get file.jpg /tmp/my/stuff/
```

## Compatibility Notes

- The system is designed to work across different machines (mc01-mc10, orion machines)
- Make sure the server can be reached on the specified port
- Firewall rules may need to be adjusted

