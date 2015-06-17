# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.ssh.forward_agent = true

  # Configure plugins
  unless ENV["VAGRANT_NO_PLUGINS"]

    required_plugins = %w( vagrant-hostmanager vagrant-cachier landrush vagrant-librarian-puppet)
    required_plugins.each do |plugin|
      system "vagrant plugin install #{plugin}" unless Vagrant.has_plugin? plugin
    end

    # Use landrush to manage DNS entries
    # Check status with : vagrant landrush status
    if Vagrant.has_plugin?("landrush")
      config.landrush.enabled = true
    end
   # $ vagrant plugin install vagrant-hostmanager
   if Vagrant.has_plugin?("vagrant-hostmanager")
     config.hostmanager.enabled = true
   end
    # $ vagrant plugin install vagrant-cachier
    # Need nfs-kernel-server system package on debian/ubuntu host
    if Vagrant.has_plugin?("vagrant-cachier")
      config.cache.scope = :box
      config.cache.synced_folder_opts = {
        type: :nfs,
        # The nolock option can be useful for an NFSv3 client that wants to avoid the
        # NLM sideband protocol. Without this option, apt-get might hang if it tries
        # to lock files needed for /var/cache/* operations. All of this can be avoided
        # by using NFSv4 everywhere. Please note that the tcp option is not the default.
        mount_options: ['rw', 'vers=3', 'tcp', 'nolock']
      }
    end
  end

  config.vm.synced_folder "puppet/files", "/etc/puppet/files"

  config.vm.box = 'ubuntu/trusty64'

# Buggy?
#  if Vagrant.has_plugin?("vagrant-librarian-puppet")
#    config.librarian_puppet.puppetfile_dir = "puppet-contrib"
#    config.librarian_puppet.resolve_options = { :force => true }
#  end

# Monitor 
  config.vm.define "monitor" do |monitor|
    monitor.vm.hostname = 'monitor.vagrant.dev'
    # frontend network
    monitor.vm.network :private_network, ip: '192.168.66.2'
    # backend network (farms)
    monitor.vm.network :private_network, ip: '192.168.65.2'
  
    monitor.vm.provider :virtualbox do |vb|
      vb.customize ['modifyvm', :id, '--memory', '768']
    end
  end

# HA-PROXY 
  config.vm.define "ha-proxy", primary: true do |lb|
    lb.vm.hostname = 'ha-proxy.vagrant.dev'
    # frontend network
    lb.vm.network :private_network, ip: '192.168.66.5'
    # backend network (farms)
    lb.vm.network :private_network, ip: '192.168.65.5'
  
    lb.vm.provider :virtualbox do |vb|
      vb.customize ['modifyvm', :id, '--memory', '512']
    end
  end

# SP
  # VIP for the shibboleth-sp
  config.landrush.host 'shibboleth-sp.vagrant.dev', '192.168.66.10'

  sp_servers = { :'shibboleth-sp1' => '192.168.65.11',
                  :'shibboleth-sp2' => '192.168.65.12'
                }

  sp_servers.each do |sp_server_name, sp_server_ip| 
     config.vm.define sp_server_name do |sp|
       sp.vm.hostname = sp_server_name.to_s + ".vagrant.dev"
       sp.vm.network :private_network, ip: sp_server_ip
       sp.vm.provider :virtualbox do |vb|
         vb.customize ['modifyvm', :id, '--memory', '512']
       end
     end
  end

# IDP
  # VIP for the shibboleth-idp
  config.landrush.host 'shibboleth-idp.vagrant.dev', '192.168.66.20'

  idp_servers = { :'shibboleth-idp1' => '192.168.65.21',
                  :'shibboleth-idp2' => '192.168.65.22'
                }

  idp_servers.each do |idp_server_name, idp_server_ip| 
    config.vm.define idp_server_name do |idp|
      idp.vm.hostname = idp_server_name.to_s + ".vagrant.dev"
      idp.vm.network :private_network, ip: idp_server_ip 
  
      idp.vm.provider :virtualbox do |vb|
        vb.customize ['modifyvm', :id, '--memory', '768']
      end
    end
  end

# Gatling

  config.vm.define "gatling", autostart: false do |gatling|
    gatling.vm.hostname = 'gatling.vagrant.dev'
    gatling.vm.network :private_network, ip: '192.168.66.7'
    gatling.vm.provider :virtualbox do |vb|
      vb.customize ['modifyvm', :id, '--memory', '768']
    end
  end

# Puppet provisionning
  config.vm.provision :puppet do |puppet|
      puppet.manifests_path = "puppet/manifests"
      puppet.manifest_file = "01_site.pp"
      puppet.module_path = [ "puppet/modules", "puppet-contrib/modules"]
      puppet.hiera_config_path = "puppet/hiera.yaml"
      puppet.options="--fileserverconfig=/vagrant/puppet/fileserver.conf"
    end
end

