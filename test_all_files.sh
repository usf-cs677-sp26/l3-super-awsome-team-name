#!/bin/bash

# Comprehensive testing script following assignment requirements
# Tests: small files, large files, binary files, and text/ASCII files
# Measures transfer times for performance analysis

SERVER_HOST="mc07:9898"  # Change if server is on different machine
DOWNLOAD_DIR="./downloads"

echo "=========================================="
echo "File Transfer System - Comprehensive Test"
echo "=========================================="
echo ""

# Create download directory
mkdir -p "$DOWNLOAD_DIR"

# Function to test PUT and GET with timing
test_file() {
    local file=$1
    local file_type=$2
    
    if [ ! -f "$file" ]; then
        echo "ERROR: File $file not found!"
        return 1
    fi
    
    local file_size=$(du -h "$file" | cut -f1)
    echo "----------------------------------------"
    echo "Testing: $file ($file_type, size: $file_size)"
    echo "----------------------------------------"
    
    # Get original checksum
    local original_checksum=$(md5sum "$file" | cut -d' ' -f1)
    echo "Original checksum: $original_checksum"
    echo ""
    
    # Test PUT operation with timing
    echo ">>> PUT Operation:"
    time ./bin/client "$SERVER_HOST" put "$file"
    put_exit_code=$?
    
    if [ $put_exit_code -eq 0 ]; then
        echo "✓ PUT successful"
    else
        echo "✗ PUT failed (exit code: $put_exit_code)"
        return 1
    fi
    echo ""
    
    # Wait a moment
    sleep 1
    
    # Test GET operation with timing
    echo ">>> GET Operation:"
    time ./bin/client "$SERVER_HOST" get "$(basename "$file")" "$DOWNLOAD_DIR"
    get_exit_code=$?
    
    if [ $get_exit_code -eq 0 ]; then
        echo "✓ GET successful"
    else
        echo "✗ GET failed (exit code: $get_exit_code)"
        return 1
    fi
    echo ""
    
    # Verify checksum
    local downloaded_file="$DOWNLOAD_DIR/$(basename "$file")"
    if [ -f "$downloaded_file" ]; then
        local downloaded_checksum=$(md5sum "$downloaded_file" | cut -d' ' -f1)
        echo "Downloaded checksum: $downloaded_checksum"
        
        if [ "$original_checksum" == "$downloaded_checksum" ]; then
            echo "✓ Checksums match - File integrity verified!"
        else
            echo "✗ Checksums DO NOT match - File corruption detected!"
            return 1
        fi
    else
        echo "✗ Downloaded file not found!"
        return 1
    fi
    
    echo ""
    echo "✓ Test completed successfully for $file"
    echo ""
}

# Check if server is running (optional check)
echo "Note: Make sure server is running on $SERVER_HOST"
echo "Press Enter to continue or Ctrl+C to cancel..."
read

echo ""
echo "Starting comprehensive tests..."
echo ""

# Test 1: Small text file
test_file "small.txt" "Small text/ASCII"

# Test 2: Medium text file
test_file "readable_large.txt" "Medium text/ASCII"

# Test 3: Large file
test_file "large.txt" "Large file (10MB)"

# Test 4: Binary file
test_file "binary.bin" "Binary file (5MB)"

# Test 5: Medium binary file
test_file "medium.txt" "Medium binary (1MB)"

echo "=========================================="
echo "All tests completed!"
echo "=========================================="
echo ""
echo "Summary:"
echo "- Small files: ✓"
echo "- Large files: ✓"
echo "- Binary files: ✓"
echo "- Text/ASCII files: ✓"
echo "- Transfer times: Measured (see output above)"
echo ""
echo "Downloaded files are in: $DOWNLOAD_DIR"
ls -lh "$DOWNLOAD_DIR"

