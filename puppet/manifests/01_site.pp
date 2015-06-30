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

# Global vars

# SP 
$shibboleth_sp_URL = 'shibboleth-sp.vagrant.dev'

# IdP
$shibboleth_idp_URL = 'shibboleth-idp.vagrant.dev'

# LDAP
$ldap_suffix = 'dc=vagrant,dc=dev'
$ldap_admin = 'admin'
$ldap_admin_pw = 'vagrant'
$ldap_uri = 'ldap://192.168.65.5'

import '02_nodes/*.pp'

