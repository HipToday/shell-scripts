#!/bin/ksh

set -e

# Default output destination
OUTFILE="/var/unbound/etc/adservers.conf"
DISABLE=0

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
    # Comma-separated whitelist of domains (https://pgl.yoyo.org/as/formats.php#skip)
    SKIP="click.redditmail.com,ipstack.com"

	# Update ad server list
	SERVERLIST_URL="https://pgl.yoyo.org/adservers/serverlist.php?hostformat=unbound&showintro=0&mimetype=plaintext&useip=$USEIP&skip=$SKIP"
	ftp -o "$OUTFILE" "$SERVERLIST_URL"
fi

rcctl reload unbound
