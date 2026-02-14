#!/usr/bin/env bash
# Spins up a tmux session with server (left) and client (right) panes

SESSION="file-transfer"

# Kill existing session if it exists
tmux has-session -t "$SESSION" 2>/dev/null && tmux kill-session -t "$SESSION"

# Create new session, left pane starts the server
tmux new-session -d -s "$SESSION" -c "$(dirname "$0")/.."

# Split into two vertical panes
tmux split-window -h -t "$SESSION" -c "$(dirname "$0")/.."

# Label panes via pane titles
tmux select-pane -t "$SESSION:0.0" -T "server"
tmux select-pane -t "$SESSION:0.1" -T "client"

# Focus the client pane (right) so you can start running commands
tmux select-pane -t "$SESSION:0.1"

tmux attach -t "$SESSION"
