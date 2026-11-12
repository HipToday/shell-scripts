#!/bin/ksh

# Sweep candidate MTU sizes across the VPN to find the largest MTU that should
# be configured on a client.
#
# For each candidate ICMP payload size, send pings with the Don't Fragment bit
# set (-D) to a host on the far side of the VPN (10.0.1.2). If the packet fits
# through the tunnel unfragmented, the ping succeeds; if it is too large, it is
# dropped (or rejected), and the ping fails. Failures are classified as either:
#   - TOO LARGE:        OpenBSD ping reported "Message too long" (local
#                       rejection) or "frag needed and DF set" (ICMP from a
#                       router), meaning something explicitly rejected it
#   - SILENTLY DROPPED: ping got no reply and no error, meaning a device on the
#                       path discarded the packet without sending ICMP feedback
#
# The MTU is the payload size plus 28 bytes of overhead (20-byte IP header +
# 8-byte ICMP header). The largest size reported "OK" is the maximum MTU that
# works over the VPN, and is the value to configure on the client.

# Usage: mtu_sweep.sh [-v]
#   -v  verbose: also print the raw ping output under each result
verbose=0
while getopts v opt; do
    case $opt in
        v) verbose=1 ;;
        *) print "Usage: ${0##*/} [-v]" >&2; exit 1 ;;
    esac
done

for size in 1252 1292 1312 1332 1392; do
    mtu=$((size + 28))
    output=$(ping -c 1 -w 2 -D -s $size 10.0.1.2 2>&1)
    rc=$?

    if [[ $rc -eq 0 ]]; then
        print "MTU ${mtu} (payload ${size}): OK"
    elif print -r -- "$output" | grep -qiE 'message too long|frag needed'; then
        # The packet was explicitly rejected because it exceeds a link MTU
        print "MTU ${mtu} (payload ${size}): TOO LARGE (rejected with an error)"
    else
        # No reply and no error: something along the path discarded it silently
        print "MTU ${mtu} (payload ${size}): SILENTLY DROPPED (no reply, no error)"
    fi
    if [[ $verbose -eq 1 ]]; then
        print -r -- "$output" | sed 's/^/    /'
        print
    fi
done