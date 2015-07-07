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

# Configure nodes
import '02_nodes/*.pp'

