#!/bin/bash

# Script to install frontend dependencies
# Usage: ./install.sh

set -e

echo "Installing frontend dependencies..."

cd "$(dirname "$0")"
npm install

echo "Installation completed!"
