#!/bin/bash
# Check if app is running on port 3000
sleep 5
if curl -s http://localhost:3000 > /dev/null; then
    echo "Service is running!"
    exit 0
else
    echo "Service failed to start!"
    exit 1
fi