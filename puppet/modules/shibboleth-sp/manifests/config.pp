class shibboleth-sp::config (
  $document_root = '/var/www/html',
  $port          = '80',
) {
  # Create self signed certificate for apache
  file { '/etc/apache2/ssl/':
  ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755'
  }

  exec { 'genapacheselfsigned':
    command     => "openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/apache2/ssl/apache.key -out /etc/apache2/ssl/apache.crt -subj \"/C=US/ST=Illinois/L=Chicago/O=vagrant/CN=shibboleth.vagrant.dev\"",
    user        => 'root',
    cwd         => '/etc/apache2/',
    creates     => '/etc/apache2/ssl/apache.key'
  }

  # Set up Apache
  # https://github.com/puppetlabs/puppetlabs-apache
  class{'apache': 
    default_vhost => false,
  }
  #class{'apache::mod::proxy_ajp': }
  class{'apache::mod::shib': }

  apache::vhost { 'shibboleth.vagrant.dev':
      port        => $port,
      docroot     => $document_root,
  }

  # https://github.com/aethylred/puppet-shibboleth
  class{'shibboleth': }
}

