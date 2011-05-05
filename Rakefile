# vim: set fdm=marker fdc=3 fdl=5:
$VERBOSE=nil
require "rubygems"
require "rest_client"
# require "nestful"
require "ostruct"
require "json"
require "yaml"
require "pp"

# RakeHelper for use enviroment variables as command line parameters {{{
#==================================================================
module RakeHelper
  def required_env(*required)
    empty_envs = []
    required = required.map {|e| e.to_s }
    required.each do |key|
      empty_envs << key unless ( ENV.has_key?(key) and ! ENV[key].to_s.empty? )
    end

    unless empty_envs.empty?
      puts empty_envs.map {|e| "'#{e}'" }.join(' and ') + " required! "
      exit 1
    end
  end

  def env
    @env ||= OpenStruct.new(ENV) # !> method redefined; discarding old split_version
    @env
  end
end
include RakeHelper

def confirm(msg)
  print "#{msg}[yes/no]: "
  STDIN.readline.chomp.downcase == "yes"
end

def settings
  @config ||= lambda {
    YAML.load_file("settings.yml")
    OpenStruct.new(YAML.load_file("settings.yml"))
  }.call
end

# }}}

# pp config


def GET(url)
  puts RestClient.get(url)
end

def POST(url,opt={})
  puts RestClient.post(url,{},{})
end

API_BASE = settings.api_base

# GET  "#{API_BASE}/host/ub01/json"
# GET  "#{API_BASE}/host/ub01/list"
# POST "#{API_BASE}/host/ub01/create"
# POST "#{API_BASE}/host/ub01/start"
# POST "#{API_BASE}/host/ub01/end"
namespace :host do
  desc "list"
  task :list do
    required_env :host
    GET "#{API_BASE}/host/#{env.host}/list"
  end
  desc "json"
  task :json do
    required_env :host
    GET  "#{API_BASE}/host/#{env.host}/json"
  end
end

# POST "#{API_BASE}/dhcp/ub01/lock"
# POST "#{API_BASE}/dhcp/ub01/unlock"
# POST "#{API_BASE}/dhcp/all/gen"
namespace :dhcp do
  desc "lock"
  task :lock do
    required_env :host
    POST  "#{API_BASE}/dhcp/#{env.host}/list"
  end
  desc "unlock"
  task :unlock do
    required_env :host
    POST  "#{API_BASE}/dhcp/#{env.host}/json"
  end
  desc "gen"
  task :gen do
    # required_env :host
    POST  "#{API_BASE}/dhcp/all/gen"
  end
end

# GET  "#{API_BASE}/boot/web01"
# POST "#{API_BASE}/boot/all"
namespace :boot do
  desc "show"
  task :show do
    required_env :host
    GET  "#{API_BASE}/boot/#{env.host}"
  end
  desc "gen"
  task :gen do
    required_env :host
    POST "#{API_BASE}/boot/#{env.host}"
  end
end

# GET  "#{API_BASE}/install/ub01"
# GET  "#{API_BASE}/install/ub01?template=centos"
namespace :install do
  desc "show"
  task :show do
    required_env :host
    query = env.template ? "?template=#{env.template}" : ""
    GET "#{API_BASE}/install/#{env.host}#{query}"
  end
  desc "template_list"
  task :template_list do
    puts Dir.glob("templates/install/*.erb").map {|e| File.basename(e, ".erb") }
  end
end

namespace :mirror do #{{{
  desc "import"
  task :import do
    required_env :from, :name
    dst = "#{settings.mirror_dir}/#{env.name}/"
    sh "mkdir -p #{dst}" unless File.directory?(dst)
    sh "rsync -a  '#{env.from}/' #{dst} --progress"
  end

  # desc "trash"
  # task :trash do
    # required_env :name
    # dst = "#{DIST_ROOT}/#{env.name}/"
    # if File.directory? dst
      # sh "mv #{dst} #{TRASH_ROOT}"
    # end
  # end

  desc "list"
  task :list do
    puts Dir.glob("#{settings.mirror_dir}/*").map {|e| File.basename(e)}
  end

  desc "find"
  task :find do
    required_env :name, :pattern
    dst = "#{settings.mirror_dir}/#{env.name}/"
    sh "find #{dst} -type f -name '*#{env.pattern}*'"
  end
end #}}}
