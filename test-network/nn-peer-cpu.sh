
#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./nn-peer-cpu.sh before
#   ./nn-peer-cpu.sh after

PHASE="${1:-}"

if [[ "$PHASE" != "before" && "$PHASE" != "after" ]]; then
    echo "Usage: $0 before|after"
    exit 1
fi

OUTPUT="cpu-${PHASE}.csv"

echo "container,cpu_seconds" > "$OUTPUT"

for org in 1 2 3; do
    for peer in $(seq 0 9); do
        container="peer${peer}.org${org}.example.com"

        # Read cumulative CPU use (cgroup v2).
        usage=$(docker exec "$container" \
            cat /sys/fs/cgroup/cpu.stat |
            awk '$1=="usage_usec" {print $2}')

        if [[ -z "$usage" ]]; then
            echo "Cannot read CPU usage for $container" >&2
            exit 1
        fi

        seconds=$(awk -v u="$usage" \
            'BEGIN {printf "%.6f", u/1000000}')

        echo "$container,$seconds" >> "$OUTPUT"
    done
done

echo "Saved $OUTPUT"
