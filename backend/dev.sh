#!/bin/bash

# Script to start backend development server
# Usage: ./dev.sh

set -e

echo "Starting backend development server..."

cd "$(dirname "$0")"
npm run dev
