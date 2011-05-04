#!/usr/bin/env ruby

module PXElerator
end

require "rubygems"
require "json"

module PXElerator
  class Host
    attr_accessor :_parent, :hostname, :macaddr, :int, :gateway
    def initialize(hostname, macaddr = nil)
      @hostname = hostname
      @macaddr = macaddr
      @int = {}
    end
    def to_json
      h = {}
      instance_variables.map do |var|
        h[var.sub(/^@/,"")] = self.instance_variable_get(var)
      end
      h.to_json
    end
    def pretty_json
      JSON.pretty_generate(JSON.parse(self.to_json))
    end
  end
end

esx01 = PXElerator::Host.new("esx01")
esx01.macaddr = "08:00:27:E9:89:45"
esx01.int["vnic0"] = { "ip" => "33.33.33.103" , "netmask" => "255.255.255.0" }
esx01.int["vnic1"] = { "ip" => "192.168.2.103", "netmask" => "255.255.255.0" }
esx01.gateway = "33.33.33.10"
esx01._parent = "_esx4.1u1"
puts esx01.pretty_json
 # => nil

# parse_ip("192.168.1.1/24") # => ["192.168.1.1", "255.255.255.0"]
def parse_ip(str)
  ip, prefix = str.split("/")
  n = prefix.to_i
  netbit = "1" * n
  hostbit = "0" * (32-n)
  netmask = "#{netbit}#{hostbit}".scan(/\d{8}/).map {|e| e.to_i(2)}.join(".")
  [ip, netmask]
end

def host_parse(conf)
  _parent, hostname, macaddr, gateway, int1, int1_ip, int2, int2_ip = conf
  h = PXElerator::Host.new(hostname,macaddr)
  h.gateway = gateway
  h._parent = _parent
  int1_ip, int1_netmask = parse_ip(int1_ip)
  int2_ip, int2_netmask = parse_ip(int2_ip)
  h.int[int1] = {"ip" => int1_ip, "netmask" => int1_netmask }
  h.int[int2] = {"ip" => int2_ip, "netmask" => int2_netmask }
  h.pretty_json
end

CONFIG =<<'EOS'
"_centos56", "web01", "08:00:27:D8:63:72", "33.33.33.10", "eth0", "33.33.33.101/24","eth1","192.168.2.101/24"
"_centos56", "web02", "08:00:27:D8:63:73", "33.33.33.11", "eth0", "33.33.33.102/24","eth1","192.168.2.102/24"
"_centos56", "web03", "08:00:27:D8:63:74", "33.33.33.12", "eth0", "33.33.33.103/24","eth1","192.168.2.103/24"
EOS

CONFIG.split("\n").each do |host|
  puts host_parse(eval("[#{host}]"))
  puts
end

module PXElerator::Util
  def pretty_json
    JSON.pretty_generate(JSON.parse(self.to_json))
  end
  def to_json
    h = {}
    instance_variables.map do |var|
      h[var.sub(/^@/,"")] = self.instance_variable_get(var)
    end
    h.to_json
  end
end

class Dist
  @@list = {}
  class << self
    def list
      @@list
    end
  end
  attr_accessor :append, :kickstart_template, :bootmenu_template, :mirror_dir
  def initialize(name)
    @name = name
    @@list[@name.downcase] = self
  end
  def template=(template)
    @kickstart_template = template
    @bootmenu_template = template
  end
  include PXElerator::Util
end
dist_list = {}
d = Dist.new("CentOS56")
d.append = "initrd=/img/CentOS56-x86_64/initrd.img ksdevice=bootif lang=  kssendmac text"
d.mirror_dir = "CentOS56"
d.kickstart_template =  "centos.erb"
d.template = "centos.erb"
