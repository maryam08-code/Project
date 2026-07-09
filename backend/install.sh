#!/bin/bash

# Script to install backend dependencies
# Usage: ./install.sh

set -e

echo "Installing backend dependencies..."

cd "$(dirname "$0")"
npm install

echo "Installation completed!"
