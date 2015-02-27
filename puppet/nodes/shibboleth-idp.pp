######################
### Shibboleth IdP ###
######################

node /^shibboleth-idp\d*.vagrant.dev$/ {
  include baseconfig

  $shibboleth_sp_URL = 'shibboleth-sp.vagrant.dev'

  ### Add a test LDAP
  class { 'ldap::server':
    suffix  => 'dc=vagrant,dc=dev',
    rootdn  => 'cn=admin,dc=vagrant,dc=dev',
    rootpw  => 'vagrant',
  }

  class { 'ldap::client':
    uri  => 'ldap://localhost',
    base => 'dc=vagrant,dc=dev',
  } 

  Class['ldap::server'] -> Class['ldap::client']

  # Install ldap-account-manager to play with LDAP
  package {'ldap-account-manager': 
    ensure  => installed ,
    require => [Apache::Vhost['shibboleth-idp-ssl'],Class['ldap::client']],
    notify  => Service['httpd'],
  }

  file { '/var/lib/ldap-account-manager/config/lam.conf':
    ensure => directory,
    owner  => 'www-data',
    group  => 'root',
    mode   => '0600',
    source => "puppet:///files/ldap/lam.conf",
    require => Package['ldap-account-manager'],
  }

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
    source => "puppet:///files/ldap/test_users.ldif",
  }

  exec { 'import_test_ldap':
    command   => '/usr/bin/ldapadd -D "cn=admin,dc=vagrant,dc=dev" -w vagrant -f /etc/ldap/test_users.ldif',
    user      => 'openldap',
    require   => [File['/etc/ldap/test_users.ldif'],Package['ldap-utils']]
  }

  ### Shibboleth IdP
  # Services to be configured in the IdP
  #   key   - short name for service (used for config file names etc)
  #   value - URL where IdP can fetch metadata for said service
  $service_providers = {
#    'shibboleth-sp.vagrant.dev' => 'http://shibboleth-sp.vagrant.dev/Shibboleth.sso/Metadata'
    "${shibboleth_sp_URL}" => "${shibboleth_sp_URL}.xml"
  }

  # Users to be configured in the IdP (via tomcat container-based auth)
  #   key   - username
  #   value - password
  $users = {
    'shibadmin' => 'shibshib'
  }

  class { 'shibboleth-idp':
    service_providers => $service_providers,
    users             => $users,
  }

  ### Configure Apache frontend
  # Set up Apache
  # https://github.com/puppetlabs/puppetlabs-apache
  class{ 'apache': 
    default_vhost => false,
    mpm_module => 'prefork', # for lam
  }

  # for lam
  include apache::mod::php
    
  apache::vhost { 'shibboleth-idp': 
    servername      => $::fqdn,
    vhost_name      => $::fqdn,
    port            => 80,
    docroot         => '/var/www/html',
    redirect_dest   => "https://$::fqdn/",
    redirect_status => 'permanent',
  }

  include apache::mod::proxy_ajp

  $ssl_apache_key="/etc/apache2/ssl/apache.key"
  $ssl_apache_crt="/etc/apache2/ssl/apache.crt"
  apache::vhost { 'shibboleth-idp-ssl':
    servername      => $::fqdn,
    vhost_name      => $::fqdn,
    port            => 443,
    docroot         => '/var/www/html',
    ssl             => true,
    ssl_cert        => $ssl_apache_crt,
    ssl_key         => $ssl_apache_key,
    proxy_dest      => 'ajp://localhost:8009',
    no_proxy_uris   => ['/lam'],
    aliases => [
      { alias       => '/lam',
        path        => '/usr/share/ldap-account-manager',
      }
    ]
  }  

  # Create self signed certificate for apache
  file { '/etc/apache2/ssl/':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  exec { 'genapacheselfsigned':
    command     => "/usr/bin/openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ${ssl_apache_key} -out ${ssl_apache_crt} -subj \"/C=FR/ST=Bretagne/L=Rennes/O=vagrant/CN=$::fqdn\"",
    user        => 'root',
    cwd         => '/etc/apache2/',
    creates     => $ssl_apache_key,
    notify      => Service['httpd'],
  }

  Apache::Vhost['shibboleth-idp'] ->
   File['/etc/apache2/ssl/'] -> 
    Exec['genapacheselfsigned'] -> 
     Apache::Vhost['shibboleth-idp-ssl']
}
