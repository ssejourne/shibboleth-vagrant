################
### HA-PROXY ###
################

# Configure the node now
node /^ha-proxy.*$/ {
  Exec {
    path => '/usr/local/bin:/usr/bin:/usr/sbin:/bin'
  }

  hiera_include('classes')

  include baseconfig

  ### Collectd
  collectd::plugin::python::module { 'haproxy':
#    modulepath    => '/usr/lib/collectd',
    script_source => 'puppet:///files/haproxy/collectd-haproxy/haproxy.py',
    config        => {
      'Socket' => '"/var/run/haproxy.sock"',
    },
    require       => Package['haproxy'],
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
    source  => 'puppet:///files/haproxy/haproxy.cfg',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Package['haproxy'],
    notify  => Service['haproxy']
  }

  # Set VIP
  exec {'conf_idp_vip':
    command => '/sbin/ifconfig eth1:2 192.168.66.20',
    user    => 'root',
    unless  => '/sbin/ifconfig -a | grep 192.168.66.20 > /dev/null',
  }
  exec {'conf_sp_vip':
    command => '/sbin/ifconfig eth1:1 192.168.66.10',
    user    => 'root',
    unless  => '/sbin/ifconfig -a | grep 192.168.66.10 > /dev/null',
  }

  Exec['conf_idp_vip'] -> Service['haproxy']
  Exec['conf_sp_vip'] -> Service['haproxy']

#  class {'haproxy':}

#  haproxy::listen { 'idp-farm':
#    ipaddress => $::shibboleth_idp_URL,
#    ports     => '443',
#  }

### 
  ### Add a test LDAP
  class { 'ldap::server':
    suffix => $::ldap_suffix,
    rootdn => "cn=${::ldap_admin},${::ldap_suffix}",
    rootpw => $::ldap_admin_pw
  }
  
  class { 'ldap::client':
    uri  => $ldap_uri,
    base => $ldap_suffix,
  }

  Class['ldap::server'] -> Class['ldap::client']

##  # Install ldap-account-manager to play with LDAP
##  package {'ldap-account-manager':
##    ensure  => installed ,
##    require => [Apache::Vhost['shibboleth-sp-ssl'],Class['ldap::client']],
##    notify  => Service['httpd'],
##  }
##
##  file { '/var/lib/ldap-account-manager/config/lam.conf':
##    ensure => directory,
##    owner  => 'www-data',
##    group  => 'root',
##    mode   => '0600',
##    source => "puppet:///files/ldap/lam.conf",
##    require => Package['ldap-account-manager'],
##  }
##

  # import sample ldap users 
  package {'ldap-utils':
    ensure  => installed ,
    require => Class['ldap::client'],
  }

  file { '/etc/ldap/test_users.ldif':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => 'puppet:///files/ldap/test_users.ldif',
  }

  exec { 'import_test_ldap':
    command => "/usr/bin/ldapadd -D \"cn=${ldap_admin},${ldap_suffix}\" -w ${ldap_admin_pw} -f /etc/ldap/test_users.ldif && touch /tmp/ldap_import_done",
    user    => 'openldap',
    creates => '/tmp/ldap_import_done',
    require => [File['/etc/ldap/test_users.ldif'],Package['ldap-utils']]
  }

}

