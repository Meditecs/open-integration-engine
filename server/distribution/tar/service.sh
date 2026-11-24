#!/bin/sh
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$BASE_DIR/lib/app"
PID_FILE="$APP_DIR/oie.pid"
EXEC="$BASE_DIR/bin/openintegrationengine"

start() {
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo "OIE already running (PID: $(cat "$PID_FILE"))."
        exit 1
    fi
    echo "Running OIE in the background..."
    cd "$APP_DIR"
    nohup "$EXEC" > "$APP_DIR/service_stdout.log" 2>&1 &
    echo $! > "$PID_FILE"
    echo "Service initiated with PID: $(cat "$PID_FILE")."
}

stop() {
    if [ ! -f "$PID_FILE" ] || ! kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo "OIE not executing."
        rm -f "$PID_FILE"
        exit 0
    fi
    PID=$(cat "$PID_FILE")
    echo "Stopping OIE (PID: $PID)..."
    kill "$PID"
    while kill -0 "$PID" 2>/dev/null; do
        sleep 1
    done
    rm -f "$PID_FILE"
    echo "Server correctly stopped."
}

status() {
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo "Open Integration Engine is ACTIVE (PID: $(cat "$PID_FILE"))."
    else
        echo "Open Integration Engine is STOPPED."
    fi
}

case "$1" in
    start)   start ;;
    stop)    stop ;;
    restart) stop; start ;;
    status)  status ;;
    *) echo "Uso: $0 {start|stop|restart|status}" ; exit 1 ;;
esac
EOF