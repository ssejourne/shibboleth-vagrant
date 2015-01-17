Exec['apt-get-update'] -> Package <| |>

Exec {
  path => '/usr/local/bin:/usr/bin:/usr/sbin:/bin'
}

exec { 'apt-get-update':
  command => 'apt-get update'
}


node 'shibboleth-sp.vagrant.dev' {
  exec { 'apt-get update':
    command => 'apt-get update',
    timeout => 60,
    tries   => 3
  }

  # a few support packages
  package { [ 'vim-nox', 'curl' , 'ntp' ]: ensure => installed }

### Shibboleth SP
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
    command     => "openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ${ssl_apache_key} -out ${ssl_apache_crt} -subj \"/C=US/ST=Illinois/L=Chicago/O=vagrant/CN=shibboleth-sp.vagrant.dev\"",
    user        => 'root',
    cwd         => '/etc/apache2/',
    creates     => '/etc/apache2/ssl/apache.key'
  }

  # Set up Apache
  # https://github.com/puppetlabs/puppetlabs-apache
  class{'apache': 
    default_vhost => false,
  }
  
  class{'apache::mod::shib': }

  apache::vhost { 'shibboleth-sp.vagrant.dev': 
    port => 80,
    docroot => '/var/www/html',
    redirect_dest   => 'https://shibboleth-sp.vagrant.dev/',
    redirect_status => 'permanent',
  }

  apache::vhost { 'ssl-shibboleth-sp.vagrant.dev':
      vhost_name      => 'shibboleth-sp.vagrant.dev',
      port            => 443,
      docroot         => '/var/www/html',
      ssl             => true,
      ssl_cert        => $ssl_apache_crt,
      ssl_key         => $ssl_apache_key,
  }  

  # https://github.com/aethylred/puppet-shibboleth
  class{'shibboleth': }
}
