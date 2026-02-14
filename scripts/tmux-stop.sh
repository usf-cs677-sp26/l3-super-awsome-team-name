#!/usr/bin/env bash
# Tears down the file-transfer tmux session

SESSION="file-transfer"

tmux kill-session -t "$SESSION" 2>/dev/null && echo "Session '$SESSION' killed." || echo "No session '$SESSION' found."
