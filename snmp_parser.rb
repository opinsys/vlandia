#!/usr/bin/ruby

# In this file we define methods to get different kinds of information from
# our switches. We use snmp applications from Net-SNMP for queries and parse
# the output with ruby.
# 
# To understand some port related outputs from snmp applications, read the
# following.
# Example line of command output:
# Q-BRIDGE-MIB::dot1qVlanStaticUntaggedPorts.1 = Hex-STRING: FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
# One hex value is representing 4 switch ports. When a hex value is 
# converted to a binary value, it consists of 4 numbers that can only
# be 0's or 1's. Binary state tells if a certain port setting is on or off.
# First hex from left represents ports 1-4, second one ports
# 5-8, and so on. From left to right, first comes the fixed ports and
# then the logical ports. 

require 'pp'

SWITCH = "sw1"

# Find out all fixed ports
def fixed_ports(switch)
  out = %x(snmpwalk -v2c -c public #{switch} IF-MIB::ifType)
  lines = out.split("\n")
  # Some example lines of data:
  # IF-MIB::ifType.24 = INTEGER: ethernetCsmacd(6)
  # IF-MIB::ifType.53 = INTEGER: other(1)
  # IF-MIB::ifType.54 = INTEGER: ieee8023adLag(161)
  lines.select do |line|
    line.match("ethernetCsmacd")
  end.map do |line|
    line.match(/[0-9]+/)
  end
end

# Count of fixed ports
#pp fixed_ports(SWITCH).size


# Find out ports which have tagged VLANs
def tagged_ports(switch)
  out = %x(snmpwalk -v 2c -c public #{switch} dot1qVlanStaticUntaggedPorts)
  lines = out.split("\n").select { |line| line.match("Hex-STRING") }
  # Example line of data:
  # Q-BRIDGE-MIB::dot1qVlanStaticUntaggedPorts.1 = Hex-STRING: FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
  binlines = lines.map do |line|
    line.split(":")[3]
  end.map do |line|
    line.delete(' ')
  end.map do |line|
    line.hex.to_s(2).rjust(line.size*4, '0')
  end
 
  taggedports = []
  binlines.each do |line|
    binline = line.split("")
    binline.each_index do |index|
      taggedports.push(index + 1) if binline[index] == "0"
    end
  end
  taggedports.sort.uniq
end


# Find out logical LAG ports
def lag_ports(switch)
  out = %x(snmpwalk -v2c -c public #{SWITCH} IF-MIB::ifType)
  lagports = out.split("\n").select do |line|
    line.match("ieee8023adLag")
  end.map do |line|
    line.match(/[0-9]+/)
  end
end


# Find out physical ports in LAGs
def ports_in_lag(switch)
  out = %x(snmpwalk -v2c -c public #{SWITCH} IEEE8023-LAG-MIB::dot3adAggPortListPorts)
  lines = out.split("\n").select { |line| line.match("Hex-STRING") }
  # Example line of data:
  # IEEE8023-LAG-MIB::dot3adAggPortListPorts.54 = Hex-STRING: 00 00 03 00 00 00 00 00 00 00 00 00 00 00 00 00
  binlines = lines.map do |line|
    line.split(":")[3]
  end.map do |line|
    line.delete(' ')
  end.map do |line|
    line.hex.to_s(2).rjust(line.size*4, '0')
  end

  portsinlag = []
  binlines.each do |line|
    binline = line.split("")
    binline.each_index do |index|
       portsinlag.push(index + 1) if binline[index] == "1"
    end
  end
  portsinlag.sort.uniq
end
