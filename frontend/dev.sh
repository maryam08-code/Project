#!/bin/bash

# Script to start frontend development server
# Usage: ./dev.sh

set -e

echo "Starting frontend development server..."

cd "$(dirname "$0")"
npm run dev
