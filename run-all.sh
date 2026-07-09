#!/bin/bash

# Script to run both backend and frontend of E-Office application
# Usage: ./run-all.sh {start|start-backend|start-frontend|stop|status|restart|install|install-all}

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN_DIR="$SCRIPT_DIR/.run"
BACKEND_PORT="${BACKEND_PORT:-8000}"
FRONTEND_PORT="${FRONTEND_PORT:-3000}"
DB_PORT="${DB_PORT:-5432}"

mkdir -p "$RUN_DIR"

start_background() {
  local name="$1"
  local workdir="$2"
  shift 2
  local logfile="$RUN_DIR/${name}.log"
  local pidfile="$RUN_DIR/${name}.pid"

  : > "$logfile"
  (
    cd "$workdir"
    if command -v setsid >/dev/null 2>&1; then
      setsid nohup "$@" >> "$logfile" 2>&1 &
    else
      nohup "$@" >> "$logfile" 2>&1 &
    fi
    echo $! > "$pidfile"
  )
}

read_pid() {
  local pidfile="$RUN_DIR/$1.pid"
  if [ -f "$pidfile" ]; then
    cat "$pidfile"
  fi
}

is_pid_running() {
  local pid="$1"
  [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null
}

is_port_listening() {
  local port="$1"
  ss -tln 2>/dev/null | grep -q ":${port} " || \
    netstat -tln 2>/dev/null | grep -q ":${port} "
}

database_ready() {
  (
    cd "$SCRIPT_DIR/backend"
    npm run db:check >/dev/null 2>&1
  )
}

backend_ready() {
  curl -sf "http://127.0.0.1:${BACKEND_PORT}/api/health" >/dev/null 2>&1
}

frontend_ready() {
  curl -sf "http://127.0.0.1:${FRONTEND_PORT}" >/dev/null 2>&1 || \
    is_port_listening "$FRONTEND_PORT"
}

wait_for_database() {
  local attempts="${1:-30}"
  while [ "$attempts" -gt 0 ]; do
    if database_ready; then
      return 0
    fi
    sleep 1
    attempts=$((attempts - 1))
  done
  return 1
}

wait_for_backend() {
  local attempts="${1:-30}"
  while [ "$attempts" -gt 0 ]; do
    if backend_ready; then
      return 0
    fi
    sleep 1
    attempts=$((attempts - 1))
  done
  return 1
}

wait_for_frontend() {
  local attempts="${1:-60}"
  while [ "$attempts" -gt 0 ]; do
    if frontend_ready; then
      return 0
    fi
    sleep 1
    attempts=$((attempts - 1))
  done
  return 1
}

stop_pid_file() {
  local name="$1"
  local pid
  pid="$(read_pid "$name")"
  if is_pid_running "$pid"; then
    kill "$pid" 2>/dev/null || true
    sleep 1
    if is_pid_running "$pid"; then
      kill -9 "$pid" 2>/dev/null || true
    fi
  fi
  rm -f "$RUN_DIR/$name.pid"
}

# Function to start database
start_database() {
  echo "Checking PostgreSQL on port ${DB_PORT}..."

  if database_ready; then
    echo "Database is already available (eoffice_db reachable on ${DB_PORT})"
    return 0
  fi

  if is_port_listening "$DB_PORT"; then
    echo "ERROR: Port ${DB_PORT} is in use but eoffice_db is not reachable."
    echo "       Update backend/.env credentials or stop the conflicting PostgreSQL service."
    exit 1
  fi

  echo "Starting embedded PostgreSQL database..."
  start_background "database" "$SCRIPT_DIR/backend" node scripts/start-embedded-postgres.js

  if ! wait_for_database 30; then
    echo "ERROR: Embedded PostgreSQL failed to start or eoffice_db is unreachable."
    stop_pid_file "database"
    exit 1
  fi

  echo "Embedded PostgreSQL is ready"
}

run_migrations() {
  echo "Running database migrations..."
  cd "$SCRIPT_DIR/backend"
  npm run migrate
}

# Function to start backend
start_backend() {
  echo "Starting backend server..."

  if backend_ready; then
    echo "Backend is already running on http://127.0.0.1:${BACKEND_PORT}"
    return 0
  fi

  start_background "backend" "$SCRIPT_DIR/backend" npm run dev

  if ! wait_for_backend 30; then
    echo "ERROR: Backend failed to start on http://127.0.0.1:${BACKEND_PORT}"
    stop_pid_file "backend"
    exit 1
  fi

  echo "Backend is ready on http://127.0.0.1:${BACKEND_PORT}"
}

# Function to start frontend
start_frontend() {
  echo "Starting frontend server..."

  if frontend_ready; then
    echo "Frontend is already running on http://127.0.0.1:${FRONTEND_PORT}"
    return 0
  fi

  start_background "frontend" "$SCRIPT_DIR/frontend" npm run dev

  if ! wait_for_frontend 60; then
    echo "ERROR: Frontend failed to start on http://127.0.0.1:${FRONTEND_PORT}"
    stop_pid_file "frontend"
    exit 1
  fi

  echo "Frontend is ready on http://127.0.0.1:${FRONTEND_PORT}"
}

# Function to stop all services started by this script
stop_all() {
  echo "Stopping E-Office services..."
  stop_pid_file "frontend"
  stop_pid_file "backend"
  stop_pid_file "database"
  echo "All tracked services stopped"
}

# Function to check services status
check_status() {
  echo "Checking services status..."
  echo "Database:"
  if database_ready; then
    echo "  - Ready (port ${DB_PORT})"
  elif is_port_listening "$DB_PORT"; then
    echo "  - Port ${DB_PORT} in use, but eoffice_db is not reachable"
  else
    echo "  - Not running"
  fi

  echo "Backend:"
  if backend_ready; then
    echo "  - Ready (http://127.0.0.1:${BACKEND_PORT})"
  else
    echo "  - Not running"
  fi

  echo "Frontend:"
  if frontend_ready; then
    echo "  - Ready (http://127.0.0.1:${FRONTEND_PORT})"
  else
    echo "  - Not running"
  fi
}

# Function to install dependencies
install_deps() {
  echo "Installing frontend dependencies..."
  cd "$SCRIPT_DIR/frontend"
  npm install
  echo "Frontend dependencies installed!"
}

# Function to install all dependencies (frontend + backend)
install_all() {
  echo "Installing all dependencies..."
  cd "$SCRIPT_DIR/frontend"
  npm install
  cd "$SCRIPT_DIR/backend"
  npm install
  echo "All dependencies installed!"
}

# Function to run both backend and frontend
run_all() {
  echo "Starting E-Office application..."
  start_database
  run_migrations
  start_backend
  start_frontend
  echo ""
  echo "E-Office application is running!"
  echo "  - Database: localhost:${DB_PORT}"
  echo "  - Backend: http://localhost:${BACKEND_PORT}"
  echo "  - Frontend: http://localhost:${FRONTEND_PORT}"
  echo ""
  echo "Use './run-all.sh stop' to stop tracked services"
}

# Main script
case "${1:-start}" in
  start)
    run_all
    ;;
  start-backend)
    start_database
    run_migrations
    start_backend
    ;;
  start-frontend)
    start_frontend
    ;;
  stop)
    stop_all
    ;;
  status)
    check_status
    ;;
  restart)
    stop_all
    sleep 2
    run_all
    ;;
  install)
    install_deps
    ;;
  install-all)
    install_all
    ;;
  *)
    echo "Usage: $0 {start|start-backend|start-frontend|stop|status|restart|install|install-all}"
    exit 1
    ;;
esac
