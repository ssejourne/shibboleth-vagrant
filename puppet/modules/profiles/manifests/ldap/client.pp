#
class profiles::ldap::client {
  ## Hiera Lookup
  $ldap_suffix   = hiera('profiles::ldap::ldap_suffix')
  $ldap_uri      = hiera('profiles::ldap::ldap_uri')

  ##
  class { '::ldap::client':
    uri  => $ldap_uri,
    base => $ldap_suffix,
  }

  # import sample ldap users 
  package {'::ldap-utils': 
    ensure  => installed,
    require => Class['::ldap::client'],
  }
}

