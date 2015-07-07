#
class profiles::ldap::server {
  ## Hiera Lookup
  $ldap_admin    = hiera('profiles::ldap::ldap_admin')
  $ldap_suffix   = hiera('profiles::ldap::ldap_suffix')
  $ldap_admin_pw = hiera('profiles::ldap::ldap_admin_pw')
  $ldap_uri      = hiera('profiles::ldap::ldap_uri')

  ##
  class { '::ldap::server':
    suffix => $ldap_suffix,
    rootdn => "cn=${ldap_admin},${ldap_suffix}",
    rootpw => $ldap_admin_pw
  }->
  class { '::ldap::client':
    uri  => $ldap_uri,
    base => $ldap_suffix,
  }

  # import sample ldap users 
  package {'ldap-utils': 
    ensure  => installed ,
    require => Class['::ldap::client'],
  }

  file { '/etc/ldap/test_users.ldif':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source =>  'puppet:///files/ldap/test_users.ldif',
  }

  exec { 'import_test_ldap':
    command =>  "/usr/bin/ldapadd -D \"cn=${ldap_admin},${ldap_suffix}\" -w ${ldap_admin_pw} -f /etc/ldap/test_users.ldif && touch /tmp/ldap_import_done  ",
    user    => 'openldap',
    creates => '/tmp/ldap_import_done',
    require =>  [ File['/etc/ldap/test_users.ldif'] , Package['ldap-utils'] ]
  }
}

