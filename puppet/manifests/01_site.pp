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

import '02_nodes/*.pp'

