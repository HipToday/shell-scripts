#!/bin/sh

set -e

OUTFILE="/var/unbound/etc/adservers.conf"
SERVERLIST_URL="http://pgl.yoyo.org/adservers/serverlist.php?hostformat=unbound&showintro=0&mimetype=plaintext&useip=127.0.0.1"

ftp -o "$OUTFILE" "$SERVERLIST_URL"

rcctl reload unbound
