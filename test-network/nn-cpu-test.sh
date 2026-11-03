
#!/bin/bash
set -e

echo "=================================="
echo "Starting CPU measurement experiment"
echo "=================================="

# Step 1: Record CPU usage before transactions
echo "Recording initial CPU usage..."
./nn-peer-cpu.sh before

# Step 2: Submit 300 transactions
echo "Submitting transactions..."
./nn-more-peers.sh

# Step 3: Record CPU usage after transactions
echo "Recording final CPU usage..."
./nn-peer-cpu.sh after

echo "=================================="
echo "CPU measurement experiment complete"
echo "=================================="
