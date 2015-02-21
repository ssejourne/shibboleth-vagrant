Exec['apt-get-update'] -> Package <| |>

Exec {
  path => '/usr/local/bin:/usr/bin:/usr/sbin:/bin'
}

exec { 'apt-get-update':
  command => 'apt-get update',
  timeout => 60,
  tries   => 3
}


node 'shibboleth-sp.vagrant.dev' {
  # a few support packages
  package { [ 'vim-nox', 'curl' , 'ntp' ]: ensure => installed }
### Set timezone
  file { '/etc/timezone':
    content  => 'Europe/Paris',
  }

  exec { 'set_mytimezone':
    command   => 'dpkg-reconfigure -f noninteractive tzdata',
    user      => 'root',
  }

  File['/etc/timezone'] -> Exec['set_mytimezone']

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
  
  apache::vhost { 'shibboleth-sp': 
    servername      => $::fqdn,
    vhost_name      => $::fqdn,
    port => 80,
    docroot => '/var/www/html',
    redirectmatch_status => 'permanent',
    redirectmatch_regexp => ['^/(?!Shibboleth.sso)(.*)'],
    redirectmatch_dest => 'https://shibboleth-sp.vagrant.dev/',
  }

  apache::vhost { 'shibboleth-sp-ssl':
    servername      => $::fqdn,
    vhost_name      => $::fqdn,
    port            => 443,
    docroot         => '/var/www/html',
    ssl             => true,
    ssl_cert        => $ssl_apache_crt,
    ssl_key         => $ssl_apache_key,
    custom_fragment => 'UseCanonicalName On',
  }  

  class{'apache::mod::shib': }

  # https://github.com/aethylred/puppet-shibboleth
  class{'shibboleth': 
#    conf_file          => 'shibboleth2.tmp.xml',
  }

  # Set up the Shibboleth Single Sign On (sso) module
#  shibboleth::sso{'federation_directory':
#    idpURL  => 'https://shibboleth-idp.vagrant.dev/idp/shibboleth',
#  }

#  shibboleth::metadata{'federation_metadata':
#    provider_uri  => 'https://shibboleth-idp.vagrant.dev/idp/profile/Metadata/SAML',
#    cert_uri      => 'http://shibboleth-idp.vagrant.dev/',
#  }

  include shibboleth::backend_cert

## Copy shibboleth2.xml
  file{'my-shibboleth2.xml':
    ensure => file,
    path   => "${::shibboleth::params::conf_dir}/shibboleth2.xml",
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => "puppet:///files/sp/shibboleth2.xml",
    replace => true,
    require => [Class['apache::mod::shib'],File['shibboleth_conf_dir']],
    notify  => Service['httpd','shibd'],
  }

}

