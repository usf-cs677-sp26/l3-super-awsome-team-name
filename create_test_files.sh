#!/bin/bash

# Script to create test files of various sizes and types

echo "Creating test files..."

# Small text file (already have this, but creating for completeness)
echo "This is a small test file for file transfer system" > small.txt
echo "Created: small.txt"

# Medium text file (~1MB)
echo "Creating medium.txt (1MB)..."
dd if=/dev/urandom of=medium.txt bs=1024 count=1024 2>/dev/null
echo "Created: medium.txt ($(du -h medium.txt | cut -f1))"

# Large text file (~10MB)
echo "Creating large.txt (10MB)..."
dd if=/dev/urandom of=large.txt bs=1024 count=10240 2>/dev/null
echo "Created: large.txt ($(du -h large.txt | cut -f1))"

# Very large file (~50MB) - optional, comment out if too large
# echo "Creating very_large.txt (50MB)..."
# dd if=/dev/urandom of=very_large.txt bs=1024 count=51200 2>/dev/null
# echo "Created: very_large.txt ($(du -h very_large.txt | cut -f1))"

# Binary file (simulate an image or binary data)
echo "Creating binary.bin (5MB)..."
dd if=/dev/urandom of=binary.bin bs=1024 count=5120 2>/dev/null
echo "Created: binary.bin ($(du -h binary.bin | cut -f1))"

# Text file with readable content (for easier verification)
echo "Creating readable_large.txt (1MB of text)..."
for i in {1..10000}; do
    echo "This is line $i of a large text file for testing file transfer. " >> readable_large.txt
done
echo "Created: readable_large.txt ($(du -h readable_large.txt | cut -f1))"

echo ""
echo "All test files created!"
echo "Files created:"
ls -lh small.txt medium.txt large.txt binary.bin readable_large.txt 2>/dev/null

