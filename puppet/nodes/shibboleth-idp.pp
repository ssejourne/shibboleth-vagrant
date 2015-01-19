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
  package { [ 'vim-nox', 'curl', 'ntp' ]: ensure => installed }

  ### Shibboleth IdP
  # Services to be configured in the IdP
  #   key   - short name for service (used for config file names etc)
  #   value - URL where IdP can fetch metadata for said service
  $service_providers = {
  #TEMP    'my-sp' => 'http://shibboleth-sp.vagrant.dev/Shibboleth.sso/Metadata'
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

   # Create self signed certificate for apache
  file { '/etc/apache2/ssl/':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755'
  }

  $ssl_apache_key="/etc/apache2/ssl/apache.key"
  $ssl_apache_crt="/etc/apache2/ssl/apache.crt"
  exec { 'genapacheselfsigned':
    command     => "openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ${ssl_apache_key} -out ${ssl_apache_crt} -subj \"/C=US/ST=Illinois/L=Chicago/O=vagrant/CN=$::fqdn\"",
    user        => 'root',
    cwd         => '/etc/apache2/',
    creates     => '/etc/apache2/ssl/apache.key'
  }

  # Set up Apache
  # https://github.com/puppetlabs/puppetlabs-apache
  class{'apache': 
    default_vhost => false,
  }
  
  apache::vhost { 'shibboleth-idp': 
    port => 80,
    docroot => '/var/www/html',
    redirect_dest   => "https://$::fqdn/",
    redirect_status => 'permanent',
  }

  include apache::mod::proxy_ajp

  apache::vhost { 'ssl-shibboleth-idp':
      vhost_name      => $::fqdn,
      port            => 443,
      docroot         => '/var/www/html',
      ssl             => true,
      ssl_cert        => $ssl_apache_crt,
      ssl_key         => $ssl_apache_key,
      proxy_dest    => 'ajp://localhost:8009/',
      no_proxy_uris => ['/idp.crt'],
  }  

 file { '/var/www/html/idp.crt':
      ensure => link,
      target => '/opt/shibboleth-idp/credentials/idp.crt',
 }
}
