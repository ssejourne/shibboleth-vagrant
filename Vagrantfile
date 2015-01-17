# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = 'ubuntu/trusty64'
  config.ssh.forward_agent = true

  required_plugins = %w( landrush )
  required_plugins.each do |plugin|
    system "vagrant plugin install #{plugin}" unless Vagrant.has_plugin? plugin
  end
  if Vagrant.has_plugin?("landrush")
    config.landrush.enabled = true
  end

  config.vm.provider :virtualbox do |vb|
    vb.customize ['modifyvm', :id, '--memory', 2048]
  end

  config.vm.hostname = 'shibboleth.vagrant.dev'
  config.vm.network :private_network, ip: '192.168.66.10'

  config.vm.provision :puppet do |puppet|
    puppet.manifests_path = "puppet"
    puppet.manifest_file = "site.pp"
    puppet.module_path = "puppet/modules"
    #puppet.options="--verbose"
    puppet.options="--verbose --debug"
  end
end

