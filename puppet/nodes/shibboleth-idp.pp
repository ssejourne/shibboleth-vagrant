Exec['apt-get-update'] -> Package <| |>

Exec {
  path => '/usr/local/bin:/usr/bin:/usr/sbin:/bin'
}

exec { 'apt-get-update':
  command => 'apt-get update'
}


node 'shibboleth-idp.vagrant.dev' {
  exec { 'apt-get update':
    command => 'apt-get update',
    timeout => 60,
    tries   => 3
  }

  # a few support packages
  package { [ 'vim-nox', 'curl' ]: ensure => installed }

### Shibboleth IdP
  # Services to be configured in the IdP
  #   key   - short name for service (used for config file names etc)
  #   value - URL where IdP can fetch metadata for said service
  $service_providers = {
    'my-sp' => 'http://shibboleth-sp.vagrant.dev/Shibboleth.sso/Metadata'
  }

  # Users to be configured in the IdP (via tomcat container-based auth)
  #   key   - username
  #   value - password
  $users = {
    'shibadmin' => 'shibshib'
  }

  class { 'shibboleth-idp':
    service_providers => $service_providers,
    users             => $users
  }
}
