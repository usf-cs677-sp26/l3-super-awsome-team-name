# Testing Instructions - Following Assignment Requirements

## Assignment Testing Requirements

The assignment requires you to:
1. ✅ Test with **small files**
2. ✅ Test with **large files** 
3. ✅ Test with **binary files**
4. ✅ Test with **text/ASCII files**
5. ✅ **Measure the amount of time** these operations take

## Quick Test (Using Script)

On **mc08** (where you have the test files):

```bash
# Make sure server is running on mc07 first!
# On mc07: ./bin/server 9898 ./storage

# Run comprehensive test script
bash test_all_files.sh
```

This will:
- Test all file types (small, large, binary, text)
- Measure transfer times for each operation
- Verify checksums to ensure file integrity
- Show a summary at the end

## Manual Testing (Step by Step)

### Step 1: Start Server on mc07

On **mc07** (PowerShell 2):
```bash
./bin/server 9898 ./storage
```
Leave this running.

### Step 2: Test Small Text File

On **mc08**:
```bash
# Test PUT (measure time)
time ./bin/client mc07:9898 put small.txt

# Test GET (measure time)
time ./bin/client mc07:9898 get small.txt ./downloads

# Verify checksum
md5sum small.txt
md5sum downloads/small.txt
# Checksums should match!
```

### Step 3: Test Large File (10MB)

On **mc08**:
```bash
# Test PUT (measure time)
time ./bin/client mc07:9898 put large.txt

# Test GET (measure time)
time ./bin/client mc07:9898 get large.txt ./downloads

# Verify checksum
md5sum large.txt
md5sum downloads/large.txt
```

### Step 4: Test Binary File

On **mc08**:
```bash
# Test PUT (measure time)
time ./bin/client mc07:9898 put binary.bin

# Test GET (measure time)
time ./bin/client mc07:9898 get binary.bin ./downloads

# Verify checksum
md5sum binary.bin
md5sum downloads/binary.bin
```

### Step 5: Test Text/ASCII File

On **mc08**:
```bash
# Test PUT (measure time)
time ./bin/client mc07:9898 put readable_large.txt

# Test GET (measure time)
time ./bin/client mc07:9898 get readable_large.txt ./downloads

# Verify checksum
md5sum readable_large.txt
md5sum downloads/readable_large.txt
```

## Understanding the Output

The `time` command shows:
- **real**: Total elapsed time (wall clock time)
- **user**: CPU time spent in user mode
- **sys**: CPU time spent in system mode

For file transfer, focus on **real** time - this is the actual transfer time.

### Expected Performance

With gigabit links (1 Gbps = ~125 MB/s theoretical):
- Small file (< 1KB): Should be < 0.1 seconds
- Medium file (1MB): Should be < 0.1 seconds  
- Large file (10MB): Should be < 1 second
- Binary file (5MB): Should be < 0.5 seconds

Actual times will vary based on:
- Network conditions
- Server load
- File system performance

## Test Checklist

- [ ] Small text file (small.txt) - PUT and GET tested, time measured
- [ ] Large file (large.txt, 10MB) - PUT and GET tested, time measured
- [ ] Binary file (binary.bin, 5MB) - PUT and GET tested, time measured
- [ ] Text/ASCII file (readable_large.txt) - PUT and GET tested, time measured
- [ ] All checksums verified (original matches downloaded)
- [ ] Transfer times recorded

## Notes

- The assignment mentions "logs from the previous lab" - if you have those, test with them too!
- Make sure to test both directions: mc07→mc08 and mc08→mc07
- Document any issues or observations in your README

