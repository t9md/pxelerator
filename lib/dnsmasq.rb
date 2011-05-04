class DNSMasq # {{{
  class << self
    def pid
      `pidof dnsmasq`.chomp
    end

    def lock(name)
      # return name
      # return name.upcase
      _lock_or_unlock(:lock, name)
      # p CONFIG_FILE
      # refresh
    end 

    def unlock(name)
      _lock_or_unlock(:unlock, name)
      # refresh
    end 

    def _lock_or_unlock(ope, name)
      conf = read_conf
      conf.map! do |e|
        hwaddr, *rest = *e.split(",")
        if rest.last == name
          case ope
          when :lock then
            [hwaddr,"ignore",*rest[-2..-1]].join(",")
          when :unlock then
            rest.delete("ignore")
            [hwaddr, *rest].join(",")
          end
        else
          e
        end
      end
      DNSMasq.write_conf(conf)
    end

    # def add(hwaddr,ipaddr,hostname)
     # new_conf = [mac_normalize(hwaddr,":"),ipaddr,hostname].join(',')
     # conf = read_conf
     # unless conf.include?(new_conf)
       # write_conf(new_conf,true)
     # end
    # end

    def reload_required?
      @reload_required
    end

    # def del(pattern)
      # cnf = read_conf
      # del_list = cnf.grep(/#{pattern}/)
      # puts del_list
      # if confirm("delete?")
        # cnf.delete_if {|e| del_list.include?(e) }
      # end
      # write_conf(cnf)
    # end

    def refresh
      if reload_required?
        reload
        @reload_required = false
      end
    end
    
    def reload
      unless pid.empty?
        cmd = "kill -HUP #{pid}"
        system cmd
        puts "dnsmasq reloaded"
      end
    end

    def read_conf
      File.readlines(CONFIG_FILE).map {|e| e.chomp }
    end

    def write_conf(lines,append=false)
      @reload_required = true
      io_opt = append ? "a+" : "w"
      File.open(CONFIG_FILE,io_opt) do |io|
        io.puts lines
      end
    end

    def show
     puts File.read(CONFIG_FILE) if File.exist? CONFIG_FILE
    end
  end
end #}}}
