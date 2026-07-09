#!/bin/bash

# Script to install all dependencies (frontend + backend)
# Usage: ./install.sh

set -e

echo "Installing all dependencies..."

cd "$(dirname "$0")/frontend"
npm install

cd "$(dirname "$0")/backend"
npm install

echo "All dependencies installed!"
