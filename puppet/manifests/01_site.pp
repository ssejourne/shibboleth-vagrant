#
Exec {
  path => '/usr/local/bin:/usr/bin:/usr/sbin:/bin'
}

filebucket { 'main': }

# set defaults for file ownership/permissions
File {
  backup => main,
  owner  => 'root',
  group  => 'root',
  mode   => '0644',
}

## Global settings

# SP 
$shibboleth_sp_URL = hiera('shibboleth_sp_URL')

# IdP
$shibboleth_idp_URL = hiera('shibboleth_idp_URL')

# LDAP
$ldap_suffix = hiera('ldap_suffix')
$ldap_admin = hiera('ldap_admin')
$ldap_admin_pw = hiera('ldap_admin_pw')
$ldap_uri = hiera('ldap_uri')

# to configure VIPs
define configure_haproxy_vips($interface, $address) {
  notice ("configure VIP on interface ${interface} with IP ${address}")

  exec {"conf_vip_${address}":
    command => "/sbin/ifconfig ${interface} ${address}",
    user    => 'root',
    unless  => "/sbin/ifconfig -a | grep ${address} /dev/null",
    notify  => Service['haproxy']
  }
}

# Configure nodes
import '02_nodes/*.pp'

