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
    before  => Package['haproxy'],
  }

  package {'haproxy':
     ensure => installed,
  }

  file {'/etc/haproxy/haproxy.cfg':
     ensure  => present,
     source => "puppet:///files/haproxy.cfg",
     owner  => 'root',
     group  => 'root',
     mode   => '0644',
     require => Package['haproxy'],
#     notify => Service['haproxy']
  }

#  class {'haproxy':}

#  haproxy::listen { 'idp-farm':
#    ipaddress => $::shibboleth_idp_URL,
#    ports     => '443',
#  }

}

