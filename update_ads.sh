#!/bin/ksh

set -e

# Default output destination
OUTFILE="/var/unbound/etc/adservers.conf"
DISABLE=0

# Whitelist of domains to exclude from blocking
set -A WHITELIST \
    "awstrack.me" \
    "doubleclick.net" \
    "googleadservices.com" \
    "click.redditmail.com" \
    "ipstack.com" \
    "api-au.piano.io" \
    "klclick1.com" \
;

# Parse command-line arguments
while [ $# -gt 0 ]; do
	case "$1" in
		-f)
			if [ -z "$2" ]; then
				echo "Error: -f requires a file path argument" >&2
				exit 1
			fi
			OUTFILE="$2"
			shift 2
			;;
		-d|--disable)
			DISABLE=1
			shift
			;;
		*)
			echo "Error: Unknown option '$1'" >&2
			echo "Usage: $0 [-f file] [-d|--disable]" >&2
			exit 1
			;;
	esac
done

if [ "$DISABLE" -eq 1 ]; then
	# Disable ad blocking
	cp /dev/null "$OUTFILE"
else
    # IP address to redirect ad domains to
    USEIP="127.0.0.1"

    # Convert WHITELIST array to a URL encoded comma-separated string
    # see: https://pgl.yoyo.org/as/formats.php#skip
    SKIP=$(echo ${WHITELIST[@]} | sed 's/ /%2C/g')

	# Update ad server list
	SERVERLIST_URL="https://pgl.yoyo.org/adservers/serverlist.php?hostformat=unbound&showintro=0&mimetype=plaintext&useip=$USEIP&skip=$SKIP"
	ftp -o "$OUTFILE" "$SERVERLIST_URL"
fi

rcctl reload unbound
