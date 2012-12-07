#!/usr/bin/ruby

# Code to do the ports' VLAN membership changes.

port = "1"
switch = "sw3"

# Find out old pvid
out = %x(snmpget -v2c -c public #{switch} Q-BRIDGE-MIB::dot1qPvid.#{port})
oldpvid = out.match(/Gauge32: ([0-9]+)/)[1]


