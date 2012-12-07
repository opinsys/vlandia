#!/usr/bin/ruby

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

pp fixed_ports(SWITCH)

# Count of fixed ports
pp fixed_ports(SWITCH).size


# Find out ports which have tagged VLANs 
tagged = %x(snmpwalk -v 2c -c public #{switch} dot1qVlanStaticUntaggedPorts)
tagged = tagged.split("\n")
tagged = tagged.select { |line| line.match("Hex-STRING") }
tagged = tagged.map { |line| line.split(":")[3] }
tagged = tagged.map { |line| line.delete(' ') }
tagged = tagged.map { |line| line.hex.to_s(2).rjust(line.size*4, '0') }

taggedports = []
tagged.each do |line|
  new = line.split("")
  new.each_index { |index| taggedports.push(index + 1) if new[index] == "0" }
end

pp "Ports with tagged VLANs: #{taggedports.sort.uniq}" 

# Find out logical LAG-ports
lagports = %x(snmpwalk -v2c -c public #{switch} IF-MIB::ifType)
lagports = lagports.split("\n")
lagports = lagports.select { |line| line.match("ieee8023adLag") }
lagports = lagports.map { |line| line.match(/[0-9]+/) }

pp "LAG-ports: #{lagports}"

# Find out physical ports in LAGs
portsinlag = %x(snmpwalk -v2c -c public #{switch} IEEE8023-LAG-MIB::dot3adAggPortListPorts)
portsinlag = portsinlag.split("\n")
portsinlag = portsinlag.select { |line| line.match("Hex-STRING") }
portsinlag = portsinlag.map { |line| line.split(":")[3] }
portsinlag = portsinlag.map { |line| line.delete(' ') }
portsinlag = portsinlag.map { |line| line.hex.to_s(2).rjust(line.size*4, '0') }

portsinlagarray = []
portsinlag.each do |line|
  new2 = line.split("")
  new2.each_index { |index| portsinlagarray.push(index + 1) if new2[index] == "1" }   
end

pp "Physical ports in LAG: #{portsinlagarray.sort.uniq}"

