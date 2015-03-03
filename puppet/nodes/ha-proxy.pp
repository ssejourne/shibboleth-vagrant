################
### HA-PROXY ###
################

# Configure the node now
node 'ha-proxy.vagrant.dev' {
  Exec {
    path => '/usr/local/bin:/usr/bin:/usr/sbin:/bin'
  }

  include baseconfig

  # Need version 1.5
  exec {'add-apt-haproxy':
    command => '/usr/bin/add-apt-repository -y ppa:vbernat/haproxy-1.5',
    user    => 'root',
    creates => '/etc/apt/sources.list.d/vbernat-haproxy-1_5-trusty.list',
    before  => Class['haproxy'],
  }

  class {'haproxy':}

  haproxy::listen { 'idp-farm':
    ipaddress => $::shibboleth_idp_URL,
    ports     => '443',
  }

}

