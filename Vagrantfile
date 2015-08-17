# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'

CONF = YAML.load_file('vagrant.yaml')
DOMAIN = CONF['domain']

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
      config.landrush.enabled = CONF['landrush_enabled']
      config.landrush.tld = DOMAIN
    end
   # $ vagrant plugin install vagrant-hostmanager
   if Vagrant.has_plugin?("vagrant-hostmanager")
     config.hostmanager.enabled = CONF['hostmanager_enabled']
   end
    # $ vagrant plugin install vagrant-cachier
    # Need nfs-kernel-server system package on debian/ubuntu host
    if Vagrant.has_plugin?("vagrant-cachier")
      config.cache.scope = CONF['cachier_scope']
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

  if CONF.has_key?('synced_folders')
    CONF['synced_folders'].each { |target, source|
      if source
        config.vm.synced_folder source, target, :nfs => CONF['nfs'], :linux__nfs_options => ['rw', 'no_subtree_check', 'all_squash','async'], :create => true
      end
    }
  end

  config.vm.box = CONF['box']

# Buggy?
#  if Vagrant.has_plugin?("vagrant-librarian-puppet")
#    config.librarian_puppet.puppetfile_dir = "puppet-contrib"
#    config.librarian_puppet.resolve_options = { :force => true }
#  end

  # Statics hosts entries for VIPs
  if CONF['landrush']['static']
    CONF['landrush']['static'].each do |static_host|
      config.landrush.host static_host['name'], static_host['ip']
    end
  end

  CONF['servers'].each do |servers|
    config.vm.define servers['name'] do |server|
      server.vm.hostname = servers['name'] + '.' + DOMAIN

      servers['network'].each do |network|
        server.vm.network :private_network, ip: network['ip']
      end

      server.vm.provider :virtualbox do |vb|
        vb.customize ['modifyvm', :id, '--memory', servers['ram'] ]
	vb.gui = servers['gui']
      end

      # Puppet provisionning
      config.vm.provision :puppet do |puppet|
        puppet.manifests_path = "puppet/manifests"
        puppet.manifest_file = "01_site.pp"
        puppet.module_path = [ "puppet/modules", "puppet-contrib/modules"]
        puppet.hiera_config_path = "puppet/hiera.yaml"
        puppet.options="--fileserverconfig=/vagrant/puppet/fileserver.conf --verbose"
        puppet.facter = {
          "role" => servers['role']
        }
      end

    end
  end

end

