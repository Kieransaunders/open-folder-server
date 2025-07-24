#!/bin/bash

# Open Folder Server Launcher
# This script starts the folder opening background service

# Get the directory where this script is located
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Change to the project directory
cd "$DIR"

# Create logs directory if it doesn't exist
mkdir -p logs

# Start the server and log output
echo "Starting Open Folder Server..."
echo "$(date): Starting Open Folder Server" >> logs/server.log

# Check if we're running under launchd by checking for XPC_SERVICE_NAME or low SHLVL
if [ -n "$XPC_SERVICE_NAME" ] || [ "$SHLVL" = "1" ]; then
    # Running under launchd - run in foreground
    echo "Running in launchd mode (foreground)" >> logs/server.log
    exec node server.js
else
    # Running manually - run in background
    echo "Running in manual mode (background)"
    node server.js >> logs/server.log 2>&1 &
    
    # Store the process ID
    echo $! > logs/server.pid
    
    echo "Server started with PID: $(cat logs/server.pid)"
    echo "Log file: $DIR/logs/server.log"
    echo "Server running at: http://localhost:3000"
fi