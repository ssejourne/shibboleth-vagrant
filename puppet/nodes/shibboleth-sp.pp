#####################
### Shibboleth SP ###
#####################

# Create a custom class to use a static shibboleth2.xml instead of the dyn one
#  which has some constraints for a testing environment
class shibboleth_custom inherits shibboleth {
  # Copy shibboleth2.xml
  File['shibboleth_config_file'] {
    ensure => present,
    path   => "${::shibboleth::params::conf_dir}/shibboleth2.xml",
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => "puppet:///files/sp/shibboleth2.xml",
    replace => true,
    require => [Class['apache::mod::shib'],File['shibboleth_conf_dir']],
    notify  => Service['httpd','shibd'],
  }

  # do not need to do augeas changes (it may fail).
  Augeas['sp_config_resources'] {
    changes => '',
  }
  Augeas['sp_config_consistent_address'] {
    changes => '',
  }
  Augeas['sp_config_hostname'] {
    changes => '',
  }
  Augeas['sp_config_handlerSSL'] {
    changes => '',
  }
}

# Configure the node now
node 'shibboleth-sp.vagrant.dev' {
  Exec {
    path => '/usr/local/bin:/usr/bin:/usr/sbin:/bin'
  }

  include baseconfig

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
    command     => "/usr/bin/openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ${ssl_apache_key} -out ${ssl_apache_crt} -subj \"/C=US/ST=Illinois/L=Chicago/O=vagrant/CN=shibboleth-sp.vagrant.dev\"",
    user        => 'root',
    cwd         => '/etc/apache2/',
    creates     => '/etc/apache2/ssl/apache.key'
  }

  # Set up Apache
  # https://github.com/puppetlabs/puppetlabs-apache
  class{'apache': 
    default_vhost => false,
    mpm_module => 'prefork'
  }

  class{'apache::mod::shib': }
  class{'apache::mod::php': }
  
  apache::vhost { 'shibboleth-sp': 
    servername      => $::fqdn,
    vhost_name      => $::fqdn,
    port => 80,
    docroot => '/var/www/html',
    redirect_status => 'permanent',
    redirect_dest => 'https://shibboleth-sp.vagrant.dev/',
  }

  apache::vhost { 'shibboleth-sp-ssl':
    servername      => $::fqdn,
    vhost_name      => $::fqdn,
    port            => 443,
    docroot         => '/var/www/html',
    ssl             => true,
    ssl_cert        => $ssl_apache_crt,
    ssl_key         => $ssl_apache_key,
    custom_fragment => 'UseCanonicalName On

    <Location /secure>
      AuthType shibboleth
      ShibRequestSetting requireSession 1
      require valid-user
    </Location>
    ',
  }  

  file { '/var/www/html/secure':
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0755'
  }

  file { 'shibenv.php':
    ensure => present,
    path   => '/var/www/html/secure/index.php',
    owner  => root,
    group  => root,
    mode   => '0644',
    source => 'puppet:///files/sp/shibenv.php'
  }
    
  # https://github.com/aethylred/puppet-shibboleth
  # custom to use a static shibboleth2.xml for tests
  class{'shibboleth_custom': 
  }

  # Create backend certificate, that match the metadatafile for the idp (shibboleth-sp.vagrant.dev.xml)
  file { 'sp-cert.pem':
    ensure  => present,
    path    => "${::shibboleth::conf_dir}/sp-cert.pem",
    owner   => '_shibd',
    group   => '_shibd',
    mode    => '0644',
    source  => 'puppet:///files/sp/sp-cert.pem',
    notify  => Service['httpd','shibd'],
  }
  
  file { 'sp-key.pem':
    ensure  => present,
    path    => "${::shibboleth::conf_dir}/sp-key.pem",
    owner   => '_shibd',
    group   => '_shibd',
    mode    => '0600',
    source  => 'puppet:///files/sp/sp-key.pem',
    notify  => Service['httpd','shibd'],
  }

}

