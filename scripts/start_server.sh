#!/bin/bash
# Start the app with PM2
cd /home/ubuntu/app
pm2 start index.js --name "node-app"
pm2 save
echo "Server started"