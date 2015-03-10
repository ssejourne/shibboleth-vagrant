################
### HA-PROXY ###
################

# Configure the node now
node 'ha-proxy.vagrant.dev' {
  Exec {
    path => '/usr/local/bin:/usr/bin:/usr/sbin:/bin'
  }

  include baseconfig

  ### Collectd
  #include collectd

  class { '::collectd':
    purge        => true,
    recurse      => true,
    purge_config => true,
  }

  collectd::plugin { 'cpu': }
  collectd::plugin { 'load': }
  collectd::plugin { 'memory': }
  collectd::plugin { 'swap': }
  collectd::plugin { 'disk': }
  collectd::plugin { 'interface': }
  #collectd::plugin { 'apache': }
  collectd::plugin { 'python': }
  class { 'collectd::plugin::write_graphite':
    graphitehost => 'monitor.vagrant.dev',
  }

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

  service { 'haproxy':
      ensure     => 'running',
      enable     => true,
      name       => 'haproxy',
      hasrestart => true,
      hasstatus  => true,
    }

  file {'/etc/haproxy/haproxy.cfg':
     ensure  => present,
     source  => "puppet:///files/haproxy/haproxy.cfg",
     owner   => 'root',
     group   => 'root',
     mode    => '0644',
     require => Package['haproxy'],
     notify  => Service['haproxy']
  }

  # Set VIP
  exec {'conf_idp_vip':
     command => "/sbin/ifconfig eth1:1 192.168.66.20",
     user    => 'root',
     unless  => "/sbin/ifconfig -a | grep 192.168.66.20 > /dev/null",
     notify  => Service['haproxy']
  }
#  class {'haproxy':}

#  haproxy::listen { 'idp-farm':
#    ipaddress => $::shibboleth_idp_URL,
#    ports     => '443',
#  }

}

