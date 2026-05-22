@echo off
setlocal

set "NODE_DIR=C:\Program Files\nodejs"
if not exist "%NODE_DIR%\node.exe" (
  echo Node.js tidak ditemukan di %NODE_DIR%. Install Node.js LTS terlebih dahulu.
  exit /b 1
)

set "PATH=%NODE_DIR%;%PATH%"
cd /d "%~dp0"
"%NODE_DIR%\npm.cmd" install
