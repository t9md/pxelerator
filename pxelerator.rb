require "rubygems"
gem 'sinatra', '=1.2.3'
# gem 'rack', '=1.2.0'
require 'sinatra'
# require "sinatra/settings"
require "sinatra/config_file"
require "json"
require "pp"
require "logger"

__DIR__ = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH.unshift File.join([__DIR__, "lib"])
require "dnsmasq"

# Config:
configure do # {{{
  # set :logging, 'true'
  config_file "settings.yml"
  def fj(*a) File.join(*a) end
  set :views, ['views', 'templates']
  set :show_settings, true
  set(:template_root){ fj(root,"templates") }

  if not defined?(settings.hosts_root)
    set(:hosts_root){ fj(root, "hosts")} 
  end

  set :lock, true

  Log = Logger.new("sinatra.log")
  Log.level  = Logger::INFO 
  DNSMasq::CONFIG_FILE = settings.dnsmasq_conf
end #}}}

# Helpers:
helpers do # {{{
  def install_url_for(hostname, template=nil)
    query = template ? "?template=#{template}" : ""
    "#{settings.api_base}/install/#{hostname}#{query}"
  end
  def report_url_for(hostname, action)
    "#{settings.api_base}/report/#{hostname}/#{action}"
  end
  def bootfile_path_for(hostname)
    "#{settings.pxelinux_cfg_dir}/01-#{mac_normalize(hosts_config[hostname]['macaddr'])}"
  end
  def mirror_url_for(dirname)
    "#{settings.mirror_url}/#{dirname}"
  end
  def gen_pxeboot_menu(opt)
    @c = opt
    template = File.join(settings.template_root, "boot/#{opt['bootmenu']}.erb")
    return ERB.new(File.read(template), nil, '-').result(binding)
  end
  def find_template(views, name, engine, &block)
    Array(views).each { |v| super(v, name, engine, &block) }
  end
  def mac_normalize(macaddr, sep='-')
    macaddr.gsub(/[-:]/,'').scan(/../).join(sep).tr('A-Z','a-z')
  end
  def dump_env()
    ENV.each { |k,v| log "#{k} => #{v}" }
  end
  def hosts_config
    @hosts_config ||= lambda { 
      h = {}
      Dir.glob("#{settings.hosts_root}/*.json").each do |file|
        h[File.basename(file,".json")] = JSON.parse(File.read(file))
      end
      # merge with _parent
      h.each do |name, conf|
        next if name =~ /^_/
        if conf.has_key?('_parent')
          parent_name = conf['_parent']
          h[name] = h[parent_name].merge(conf)
        end
      end
      h
    }.call
  end
  def snippet(name, options={})
    partial(:"snippet/#{name}", options)
  end
  def partial(page, options={})
    erb page, options.merge!(:layout => false)
  end
end #}}}

get  '/' do #{{{
  erb :index
end #}}}
get  '/install/:hostname' do |hn| #{{{
  content_type "text/plain"
  @c = hosts_config[hn]
  template = if params['template']
               params['template']
             else
               @c['install']
             end
  erb :"install/#{template}"
end #}}}
get '/report/:hostname/:action' do #{{{
  Log.info "#{request.ip} #{params[:hostname]} #{params[:action]}"
end #}}}
post '/dhcp/:hostname/:action' do |hn,act| #{{{
  # [ act, hn ].join(" ")
  DNSMasq.send(act,hn)
end # }}}
get  '/boot/:hostname' do |hn| #{{{
  File.read(bootfile_path_for(hn))
end #}}}
post '/boot/:hostname' do |hn| #{{{
  res = []
  dnsmasq_conf = []
  configs = if hn == 'all'
           hosts_config
         else
           h = {}
           h[hn] = hosts_config[hn]
           h
         end
  configs.each do |hostname, conf|
    next if hostname =~ /^_/
    res << hostname
    if conf['int']
      mac = conf['macaddr']
      int = conf['int']['eth0'] || conf['int']['vnic0']
      ip  = int['ip']
      dnsmasq_conf << [mac, ip , hostname ].join(',')
    end
    File.open(bootfile_path_for(hostname), 'w') do |io|
      io.puts gen_pxeboot_menu(conf)
    end
  end
  # Log.info dnsmasq_conf.inspect
  unless dnsmasq_conf.empty?
    DNSMasq.write_conf(dnsmasq_conf)
    DNSMasq.reload
  end
  res.join("\n")
end #}}}
get  '/host/:hostname/:action' do |hostname, action| #{{{
  content_type "text/plain"
  case action
  when 'list'
    if hostname == "all"
      candidate = hosts_config
    else
      candidate = { "#{hostname}" => hosts_config[hostname]}
    end
    result = []
    candidate.each do |hostname, conf|
      next if hostname =~ /^_/
      ret = "%-10s %-20s" % [hostname, conf['macaddr'] ]
      conf['int'].each do |dev, attr|
        if attr.key?("slave")
          ret << "%-5s: %-15s" % [dev, (attr['slave'] ? "slave" : "false"), nil ] 
        else
          ret << "%-5s: %-15s" % [dev, attr['ip'], attr['netmask']]
        end
      end
      result << ret
    end
    result.sort.join("\n")
  when 'json'
    hosts_config[hostname].pretty_inspect
  else
  end
end # }}}
get  '/dist' do
  "A\n"
  # Dir.glob("
end
get  '/debug' do #{{{
end #}}}
