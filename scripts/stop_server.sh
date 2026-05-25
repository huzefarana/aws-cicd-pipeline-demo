#!/bin/bash
# Stop existing app if running
cd /home/ubuntu/app
if pm2 list | grep -q "node-app"; then
    pm2 stop node-app
    pm2 delete node-app
fi
echo "Server stopped"