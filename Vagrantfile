# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.ssh.forward_agent = true

  # Configure plugins
  unless ENV["VAGRANT_NO_PLUGINS"]

    required_plugins = %w( vagrant-hostmanager vagrant-cachier landrush )
    required_plugins.each do |plugin|
      system "vagrant plugin install #{plugin}" unless Vagrant.has_plugin? plugin
    end

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


  config.vm.provider :virtualbox do |vb|
    vb.customize ['modifyvm', :id, '--memory', 2048]
  end

  config.vm.synced_folder "puppet/files", "/etc/puppet/files"

# IDP
  config.vm.define "shibboleth-idp" do |idp|
    idp.vm.box = 'ubuntu/trusty64'
    idp.vm.hostname = 'shibboleth-idp.vagrant.dev'
    idp.vm.network :private_network, ip: '192.168.66.20'

    idp.vm.provider :virtualbox do |vb|
      vb.customize ['modifyvm', :id, '--memory', '768']
    end
  end

# SP
  config.vm.define "shibboleth-sp" do |sp|
    sp.vm.box = 'ubuntu/trusty64'
    sp.vm.hostname = 'shibboleth-sp.vagrant.dev'
    sp.vm.network :private_network, ip: '192.168.66.10'
  
    sp.vm.provider :virtualbox do |vb|
      vb.customize ['modifyvm', :id, '--memory', '512']
    end
  end

  config.vm.provision :puppet do |puppet|
      puppet.manifests_path = "puppet"
      puppet.manifest_file = "site.pp"
      puppet.module_path = "puppet/modules"
      puppet.hiera_config_path = "puppet/hiera.yaml"
      puppet.options="--fileserverconfig=/vagrant/puppet/fileserver.conf --summarize"
      #puppet.options="--verbose"
      #puppet.options="--verbose --debug --trace --summarize"

      ## custom facts provided to Puppet
      puppet.facter = {
          ## tells default.pp that we're running in Vagrant
         "is_vagrant" => true,
      }
    end

end

