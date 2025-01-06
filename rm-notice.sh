#!/bin/bash

# Step 1: Change to the directory containing proxmoxlib.js and make a backup copy
cd /usr/share/javascript/proxmox-widget-toolkit/ || { echo "Failed to change directory"; exit 1; }
cp proxmoxlib.js proxmoxlib.js.bak

# Step 2: Find the lines to be commented and modify the file
sed -i '/res === null.*res === undefined.*res/{ 
  s/^/\/\// 
  n 
  s/^/\/\// 
  a\
if(false) { 
}' proxmoxlib.js
