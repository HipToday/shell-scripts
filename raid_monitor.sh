#!/bin/ksh
# /usr/local/bin/raid_monitor.sh

STATE_FILE="/var/run/mfi_state.log"
TMP_FILE="/tmp/mfi_current.log"

# 1. Capture the current status
# We exclude fluctuating values (temp/volt/current) to avoid false positives.
(
    bioctl mfi0
    sysctl hw.sensors.mfi0 | grep "indicator"
) > "$TMP_FILE"

# 2. Initialize state file if it doesn't exist
if [ ! -f "$STATE_FILE" ]; then
    cp "$TMP_FILE" "$STATE_FILE"
    exit 0
fi

# 3. Check for differences
DIFF_OUT=$(diff -u "$STATE_FILE" "$TMP_FILE")

if [ $? -ne 0 ]; then
    # 4. Send email with the diff output in the body
    (
      echo "RAID/Battery status change detected on $(hostname)"
      echo "Timestamp: $(date)"
      echo "------------------------------------------------"
      echo "$DIFF_OUT"
      echo "------------------------------------------------"
    ) | mail -s "RAID Alert: $(hostname)" root

    # 5. Update state and log to syslog
    cp "$TMP_FILE" "$STATE_FILE"
    logger -t raid_monitor "Status change detected and mailed."
fi

rm "$TMP_FILE"