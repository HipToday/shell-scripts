#!/bin/ksh

# Sweep candidate MTU sizes across the VPN to find the largest MTU that should
# be configured on a client.
#
# For each candidate ICMP payload size, send pings with the Don't Fragment bit
# set (-D) to a host on the far side of the VPN (10.0.1.2). If the packet fits
# through the tunnel unfragmented, the ping succeeds; if it is too large, it is
# dropped (or rejected), and the ping fails.
#
# The MTU is the payload size plus 28 bytes of overhead (20-byte IP header +
# 8-byte ICMP header). The largest size reported "OK" is the maximum MTU that
# works over the VPN, and is the value to configure on the client.

for size in 1252 1292 1312 1332 1392; do
    mtu=$((size + 28))
    if ping -q -c 2 -w 2 -D -s $size 10.0.1.2 >/dev/null 2>&1; then
        print "MTU ${mtu} (payload ${size}): OK"
    else
        print "MTU ${mtu} (payload ${size}): DROPPED"
    fi
done