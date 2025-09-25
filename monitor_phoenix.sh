#!/bin/bash

# Find the Phoenix process (dev mode or release)
PID=$(pgrep -f "mix phx.server")

if [ -z "$PID" ]; then
    # Try Phoenix release binary
    PID=$(pgrep -f "htmz_phx.*start")
    if [ -z "$PID" ]; then
        PID=$(pgrep -f "_build/prod/rel/htmz_phx")
    fi
fi

if [ -z "$PID" ]; then
    echo "Phoenix process not found. Make sure Phoenix server is running."
    echo "Looking for: 'mix phx.server' or 'htmz_phx start' or release binary"
    exit 1
fi

# Get CPU count for normalization
CPUS=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo "1")

# Output file (default to phoenix_monitor.csv)
OUTPUT_FILE="${1:-phoenix_monitor.csv}"

echo "Monitoring Phoenix process (PID: $PID) on $CPUS CPU cores"
echo "Writing to: $OUTPUT_FILE"
echo "Time,RSS(MB),VSZ(MB),CPU%,CPU%Norm,LoadAvg" | tee "$OUTPUT_FILE"

while kill -0 $PID 2>/dev/null; do
    TIME=$(date +"%H:%M:%S")
    LOAD=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{gsub(/ /, "", $1); print $1}')
    # Use activity monitor approach with ps (BSD style)
    DATA=$(ps -p $PID -o pid,pcpu,rss,vsz | tail -n 1 | awk -v time="$TIME" -v cpus="$CPUS" -v load="$LOAD" '{
        printf "%s,%.1f,%.1f,%.1f,%.1f,%s\n", time, $3/1024, $4/1024, $2, $2/cpus*100, load
    }')
    echo "$DATA" | tee -a "$OUTPUT_FILE"
    sleep 5
done

echo "Process $PID has terminated" | tee -a "$OUTPUT_FILE"