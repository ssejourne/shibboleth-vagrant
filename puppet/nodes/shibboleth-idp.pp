Exec['apt-get-update'] -> Package <| |>

Exec {
  path => '/usr/local/bin:/usr/bin:/usr/sbin:/bin'
}

exec { 'apt-get-update':
  command => 'apt-get update'
}


node 'shibboleth-idp.vagrant.dev' {
  # a few support packages
  package { [ 'vim-nox', 'curl', 'ntp' ]: 
    ensure => installed 
  }

  ### Set timezone
  file { '/etc/timezone':
    content  => 'Europe/Paris',
  }

  exec { 'set_mytimezone':
    command   => 'dpkg-reconfigure -f noninteractive tzdata',
    user      => 'root',
  }

  File['/etc/timezone'] -> Exec['set_mytimezone']

  ### Add a test LDAP
  class { 'ldap::server':
    suffix  => 'dc=vagrant,dc=dev',
    rootdn  => 'cn=admin,dc=vagrant,dc=dev',
    rootpw  => 'vagrant',
  }

# todo : import ldif with some test credentials

  ### Shibboleth IdP
  # Services to be configured in the IdP
  #   key   - short name for service (used for config file names etc)
  #   value - URL where IdP can fetch metadata for said service
  $service_providers = {
#    'shibboleth-sp.vagrant.dev' => 'http://shibboleth-sp.vagrant.dev/Shibboleth.sso/Metadata'
    'shibboleth-sp.vagrant.dev' => 'shibboleth-sp.vagrant.dev.xml'
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
  }
  
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
    proxy_dest      => 'ajp://localhost:8009/',
    no_proxy_uris   => ['/idp.crt'],
  }  

  # Create self signed certificate for apache
  file { '/etc/apache2/ssl/':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755'
  }

  exec { 'genapacheselfsigned':
    command     => "openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ${ssl_apache_key} -out ${ssl_apache_crt} -subj \"/C=US/ST=Illinois/L=Chicago/O=vagrant/CN=$::fqdn\"",
    user        => 'root',
    cwd         => '/etc/apache2/',
    creates     => $ssl_apache_key,
    notify      => Service['httpd'],
  }

File['/etc/apache2/ssl/'] -> Exec['genapacheselfsigned'] -> Apache::Vhost['shibboleth-idp-ssl']
}
