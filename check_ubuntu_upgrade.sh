#!/usr/bin/bash
#
# check_ubuntu_upgrade.sh - Check whether an official Ubuntu release upgrade
# is available.
#
# Runs "do-release-upgrade -c" to see if a new Ubuntu release is officially
# available. If one is, prints a notification (including the do-release-upgrade
# output and the command to run the upgrade) and creates a flag file so that
# subsequent runs exit silently without notifying again.
#
# Intended to be run periodically (e.g. from cron, where any output is mailed
# to the user). To be notified again, delete the flag file.
#
# Usage: check_ubuntu_upgrade.sh
#
# Exit status: 0 in all normal cases (upgrade found, no upgrade, or already
#              notified).
#
# Files:
#   /var/run/ubuntu_upgrade_notified  Flag file created once notification is sent.
#                                     Lives in /var/run, so it is cleared on reboot.

FLAG_FILE="/var/run/ubuntu_upgrade_notified"

# Stop checking once notification has been sent
if [ -f "$FLAG_FILE" ]; then
    exit 0
fi

OUTPUT=$(do-release-upgrade -c 2>&1)

# do-release-upgrade -c returns 0 when a release is available
if [ $? -eq 0 ] && ! echo "$OUTPUT" | grep -qi "no new release found"; then
    echo "Ubuntu upgrade is officially live on $(hostname):"
    echo ""
    echo "$OUTPUT"
    echo ""
    echo "Run: sudo do-release-upgrade"
    touch "$FLAG_FILE"
fi