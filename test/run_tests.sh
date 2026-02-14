#!/usr/bin/env bash
#
# Automated test suite for the file transfer client/server.
# Starts the server, runs PUT/GET with various file types and sizes,
# times each operation, verifies integrity via md5, and records results.
#

set -e

# ── Config ────────────────────────────────────────────────────────────────────
PORT=9898
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SERVER_BIN="$PROJECT_ROOT/bin/server"
CLIENT_BIN="$PROJECT_ROOT/bin/client"
SERVER_DIR="$PROJECT_ROOT/test/server_store"
CLIENT_DIR="$PROJECT_ROOT/test/client_recv"
TEST_FILES_DIR="$PROJECT_ROOT/test/test_files"
RESULTS_FILE="$PROJECT_ROOT/results.txt"
BIGDATA_DIR="/bigdata/datasets"

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ── Helpers ───────────────────────────────────────────────────────────────────
pass() { echo -e "  ${GREEN}PASS${NC} $1"; }
fail() { echo -e "  ${RED}FAIL${NC} $1"; FAILURES=$((FAILURES + 1)); }
info() { echo -e "${YELLOW}>>>${NC} $1"; }

cleanup() {
    info "Cleaning up..."
    if [ -n "$SERVER_PID" ] && kill -0 "$SERVER_PID" 2>/dev/null; then
        kill "$SERVER_PID" 2>/dev/null
        wait "$SERVER_PID" 2>/dev/null || true
    fi
    rm -rf "$SERVER_DIR" "$CLIENT_DIR" "$TEST_FILES_DIR"
}
trap cleanup EXIT

compute_md5() {
    if command -v md5sum &>/dev/null; then
        md5sum "$1" | awk '{print $1}'
    else
        md5 -q "$1"
    fi
}

human_size() {
    local bytes=$1
    if [ "$bytes" -ge 1073741824 ]; then
        echo "$(echo "scale=2; $bytes / 1073741824" | bc) GB"
    elif [ "$bytes" -ge 1048576 ]; then
        echo "$(echo "scale=2; $bytes / 1048576" | bc) MB"
    elif [ "$bytes" -ge 1024 ]; then
        echo "$(echo "scale=2; $bytes / 1024" | bc) KB"
    else
        echo "$bytes B"
    fi
}

file_size_bytes() {
    if [[ "$(uname)" == "Darwin" ]]; then
        stat -f%z "$1"
    else
        stat --printf="%s" "$1"
    fi
}

# ── Build ─────────────────────────────────────────────────────────────────────
info "Building project..."
make -C "$PROJECT_ROOT" clean && make -C "$PROJECT_ROOT"

# ── Setup directories ─────────────────────────────────────────────────────────
rm -rf "$SERVER_DIR" "$CLIENT_DIR" "$TEST_FILES_DIR"
mkdir -p "$SERVER_DIR" "$CLIENT_DIR" "$TEST_FILES_DIR"

# ── Generate test files ──────────────────────────────────────────────────────
info "Generating test files..."

# Small text file (~1 KB)
yes "Hello, this is a small text test file for file-transfer." | head -c 1024 > "$TEST_FILES_DIR/small-text.txt"

# Medium text file (~1 MB)
yes "Medium text file line for testing the file transfer protocol over TCP." | head -c 1048576 > "$TEST_FILES_DIR/medium-text.txt"

# Medium binary file (~1 MB)
dd if=/dev/urandom of="$TEST_FILES_DIR/medium-binary.bin" bs=1024 count=1024 2>/dev/null

# Small binary file (~10 KB)
dd if=/dev/urandom of="$TEST_FILES_DIR/small-binary.bin" bs=1024 count=10 2>/dev/null

echo ""

# ── Start server ──────────────────────────────────────────────────────────────
info "Starting server on port $PORT (storing in $SERVER_DIR)..."
"$SERVER_BIN" "$PORT" "$SERVER_DIR" &
SERVER_PID=$!
sleep 1

if ! kill -0 "$SERVER_PID" 2>/dev/null; then
    echo -e "${RED}Server failed to start!${NC}"
    exit 1
fi
info "Server running (PID: $SERVER_PID)"
echo ""

# ── Test runner ───────────────────────────────────────────────────────────────
FAILURES=0
TEST_NUM=0

# Header for results file
{
    echo "============================================"
    echo " File Transfer Test Results"
    echo " Date: $(date)"
    echo "============================================"
    echo ""
    printf "%-5s %-30s %-12s %-10s %-12s %-8s\n" "#" "File" "Size" "Operation" "Time (s)" "Status"
    echo "----------------------------------------------------------------------"
} > "$RESULTS_FILE"

run_test() {
    local test_file="$1"
    local label="$2"
    local basename
    basename=$(basename "$test_file")
    local size_bytes
    size_bytes=$(file_size_bytes "$test_file")
    local size_human
    size_human=$(human_size "$size_bytes")
    local orig_md5
    orig_md5=$(compute_md5 "$test_file")

    # ── PUT test ──────────────────────────────────────────────────────────
    TEST_NUM=$((TEST_NUM + 1))
    info "Test $TEST_NUM: PUT $label ($size_human)"

    local put_start put_end put_time
    put_start=$(date +%s.%N)
    if "$CLIENT_BIN" "localhost:$PORT" put "$test_file" 2>&1; then
        put_end=$(date +%s.%N)
        put_time=$(echo "$put_end - $put_start" | bc)

        # Verify file landed on server
        if [ -f "$SERVER_DIR/$basename" ]; then
            local server_md5
            server_md5=$(compute_md5 "$SERVER_DIR/$basename")
            if [ "$orig_md5" = "$server_md5" ]; then
                pass "PUT $label - checksum verified ($put_time s)"
                printf "%-5s %-30s %-12s %-10s %-12s %-8s\n" \
                    "$TEST_NUM" "$label" "$size_human" "PUT" "$put_time" "PASS" >> "$RESULTS_FILE"
            else
                fail "PUT $label - checksum MISMATCH (orig=$orig_md5 server=$server_md5)"
                printf "%-5s %-30s %-12s %-10s %-12s %-8s\n" \
                    "$TEST_NUM" "$label" "$size_human" "PUT" "$put_time" "FAIL" >> "$RESULTS_FILE"
            fi
        else
            fail "PUT $label - file not found on server"
            printf "%-5s %-30s %-12s %-10s %-12s %-8s\n" \
                "$TEST_NUM" "$label" "$size_human" "PUT" "-" "FAIL" >> "$RESULTS_FILE"
        fi
    else
        put_end=$(date +%s.%N)
        put_time=$(echo "$put_end - $put_start" | bc)
        fail "PUT $label - client returned error"
        printf "%-5s %-30s %-12s %-10s %-12s %-8s\n" \
            "$TEST_NUM" "$label" "$size_human" "PUT" "$put_time" "FAIL" >> "$RESULTS_FILE"
    fi

    # ── GET test ──────────────────────────────────────────────────────────
    TEST_NUM=$((TEST_NUM + 1))
    info "Test $TEST_NUM: GET $label ($size_human)"

    local get_start get_end get_time
    get_start=$(date +%s.%N)
    if "$CLIENT_BIN" "localhost:$PORT" get "$basename" "$CLIENT_DIR" 2>&1; then
        get_end=$(date +%s.%N)
        get_time=$(echo "$get_end - $get_start" | bc)

        # Verify retrieved file
        if [ -f "$CLIENT_DIR/$basename" ]; then
            local client_md5
            client_md5=$(compute_md5 "$CLIENT_DIR/$basename")
            if [ "$orig_md5" = "$client_md5" ]; then
                pass "GET $label - checksum verified ($get_time s)"
                printf "%-5s %-30s %-12s %-10s %-12s %-8s\n" \
                    "$TEST_NUM" "$label" "$size_human" "GET" "$get_time" "PASS" >> "$RESULTS_FILE"
            else
                fail "GET $label - checksum MISMATCH (orig=$orig_md5 client=$client_md5)"
                printf "%-5s %-30s %-12s %-10s %-12s %-8s\n" \
                    "$TEST_NUM" "$label" "$size_human" "GET" "$get_time" "FAIL" >> "$RESULTS_FILE"
            fi
        else
            fail "GET $label - file not found in client dir"
            printf "%-5s %-30s %-12s %-10s %-12s %-8s\n" \
                "$TEST_NUM" "$label" "$size_human" "GET" "-" "FAIL" >> "$RESULTS_FILE"
        fi
    else
        get_end=$(date +%s.%N)
        get_time=$(echo "$get_end - $get_start" | bc)
        fail "GET $label - client returned error"
        printf "%-5s %-30s %-12s %-10s %-12s %-8s\n" \
            "$TEST_NUM" "$label" "$size_human" "GET" "$get_time" "FAIL" >> "$RESULTS_FILE"
    fi

    echo ""
}

# ── Edge case: GET nonexistent file ───────────────────────────────────────────
TEST_NUM=$((TEST_NUM + 1))
info "Test $TEST_NUM: GET nonexistent file (should fail gracefully)"
if "$CLIENT_BIN" "localhost:$PORT" get "no-such-file.txt" "$CLIENT_DIR" 2>&1; then
    fail "GET nonexistent - should have failed but succeeded"
    printf "%-5s %-30s %-12s %-10s %-12s %-8s\n" \
        "$TEST_NUM" "nonexistent" "-" "GET" "-" "FAIL" >> "$RESULTS_FILE"
else
    pass "GET nonexistent - correctly rejected"
    printf "%-5s %-30s %-12s %-10s %-12s %-8s\n" \
        "$TEST_NUM" "nonexistent" "-" "GET" "-" "PASS" >> "$RESULTS_FILE"
fi

# Verify server is still alive after the failed GET
if kill -0 "$SERVER_PID" 2>/dev/null; then
    pass "Server still running after failed GET"
else
    fail "Server crashed after failed GET!"
fi
echo ""

# ── Edge case: PUT duplicate file ─────────────────────────────────────────────
# First, put a file we can try to duplicate
"$CLIENT_BIN" "localhost:$PORT" put "$TEST_FILES_DIR/small-text.txt" 2>&1 || true

TEST_NUM=$((TEST_NUM + 1))
info "Test $TEST_NUM: PUT duplicate file (should fail gracefully)"
if "$CLIENT_BIN" "localhost:$PORT" put "$TEST_FILES_DIR/small-text.txt" 2>&1; then
    fail "PUT duplicate - should have been rejected but succeeded"
    printf "%-5s %-30s %-12s %-10s %-12s %-8s\n" \
        "$TEST_NUM" "duplicate" "-" "PUT" "-" "FAIL" >> "$RESULTS_FILE"
else
    pass "PUT duplicate - correctly rejected (no overwrite)"
    printf "%-5s %-30s %-12s %-10s %-12s %-8s\n" \
        "$TEST_NUM" "duplicate" "-" "PUT" "-" "PASS" >> "$RESULTS_FILE"
fi

# Verify server is still alive after the failed PUT
if kill -0 "$SERVER_PID" 2>/dev/null; then
    pass "Server still running after failed PUT"
else
    fail "Server crashed after failed PUT!"
fi
echo ""

# Clean up the small-text.txt we just put so the real test can run
rm -f "$SERVER_DIR/small-text.txt"

# ── Run file transfer tests ──────────────────────────────────────────────────
run_test "$TEST_FILES_DIR/small-text.txt"    "small-text (1 KB)"
run_test "$TEST_FILES_DIR/small-binary.bin"  "small-binary (10 KB)"
run_test "$TEST_FILES_DIR/medium-text.txt"   "medium-text (1 MB)"
run_test "$TEST_FILES_DIR/medium-binary.bin" "medium-binary (1 MB)"

# ── Large files from /bigdata/datasets (if available) ─────────────────────────
if [ -d "$BIGDATA_DIR" ]; then
    for f in "$BIGDATA_DIR/large-log.txt" "$BIGDATA_DIR/venti-frappuchino-log.txt"; do
        if [ -f "$f" ]; then
            run_test "$f" "$(basename "$f")"
        else
            info "Skipping $f (not found)"
        fi
    done
else
    info "Skipping /bigdata/datasets tests (directory not found - run on cluster)"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
{
    echo ""
    echo "============================================"
    echo " Summary: $((TEST_NUM)) tests, $FAILURES failure(s)"
    echo "============================================"
} >> "$RESULTS_FILE"

echo ""
echo "============================================"
if [ "$FAILURES" -eq 0 ]; then
    echo -e " ${GREEN}All tests passed!${NC} ($TEST_NUM tests)"
else
    echo -e " ${RED}$FAILURES test(s) failed${NC} out of $TEST_NUM"
fi
echo " Results written to: $RESULTS_FILE"
echo "============================================"
echo ""

exit "$FAILURES"
