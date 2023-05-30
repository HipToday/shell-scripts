#!/bin/sh

set -e

# Output destination
OUTFILE="/var/unbound/etc/adservers.conf"
# IP address to redirect ad domains to
USEIP="127.0.0.1"
# Comma-separated whitelist of domains (https://pgl.yoyo.org/as/formats.php#skip)
SKIP="click.redditmail.com"
SERVERLIST_URL="https://pgl.yoyo.org/adservers/serverlist.php?hostformat=unbound&showintro=0&mimetype=plaintext&useip=$USEIP&skip=$SKIP"

ftp -o "$OUTFILE" "$SERVERLIST_URL"

rcctl reload unbound
