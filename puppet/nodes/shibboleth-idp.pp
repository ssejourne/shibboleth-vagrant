######################
### Shibboleth IdP ###
######################

node /^shibboleth-idp\d*.vagrant.dev$/ {
  include baseconfig

  ### Collectd
  #include collectd

  class { '::collectd':
    purge        => true,
    recurse      => true,
    purge_config => true,
  }

  collectd::plugin { 'cpu': }
  collectd::plugin { 'load': }
  collectd::plugin { 'memory': }
  collectd::plugin { 'swap': }
  collectd::plugin { 'disk': }
  collectd::plugin { 'interface': }

  class { 'collectd::plugin::apache':
    instances => {
      'apache80' => {
        'url' => 'http://localhost/mod_status?auto', 
      },
    },
  }
  class { 'collectd::plugin::write_graphite':
    graphitehost => 'monitor.vagrant.dev',
  }

  ### The IdP is a LDAP client
  class { 'ldap::client':
    uri  => "${ldap_uri}",
    base => "${ldap_suffix}",
  } 

  ### we need a java jdk for jmxtrans
  package {'default-jdk':
    ensure => installed,
  }

  ### Shibboleth IdP
  # Services to be configured in the IdP
  #   key   - short name for service (used for config file names etc)
  #   value - URL where IdP can fetch metadata for said service
  $service_providers = {
#    'shibboleth-sp.vagrant.dev' => "${shibboleth_sp_URL}/Shibboleth.sso/Metadata"
    "${shibboleth_sp_URL}" => "${shibboleth_sp_URL}.xml"
  }

  # Users to be configured in the IdP (via tomcat container-based auth)
  #   key   - username
  #   value - password
  $users = {
    'shibadmin' => 'shibshib'
  }

  class { 'shibboleth-idp':
    idp_hostname      => $::shibboleth_idp_URL,
    service_providers => $service_providers,
    users             => $users,
    status_page_allowed_ips => '192.168.65.1/32 192.168.65.5/32 127.0.0.1/32 ::1/128'
  }

  # use static credentials for all idp
  file {'idp.crt':
    ensure		=> present,
    path                => '/opt/shibboleth-idp/credentials/idp.crt',
    source		=> 'puppet:///files/idp/credentials/idp.crt',
    owner		=> 'root',
    group		=> 'root',
    mode		=> '0644',
    require             => Exec['shibboleth-installer'],
    notify		=> Service['tomcat6'],
  }

  file {'idp.jks':
    ensure		=> present,
    path                => '/opt/shibboleth-idp/credentials/idp.jks',
    source		=> 'puppet:///files/idp/credentials/idp.jks',
    owner		=> 'root',
    group		=> 'root',
    mode		=> '0644',
    require             => Exec['shibboleth-installer'],
    notify		=> Service['tomcat6'],
  }

  file {'idp.key':
    ensure		=> present,
    path                => '/opt/shibboleth-idp/credentials/idp.key',
    source		=> 'puppet:///files/idp/credentials/idp.key',
    owner		=> 'root',
    group		=> 'root',
    mode		=> '0644',
    require             => Exec['shibboleth-installer'],
    notify		=> Service['tomcat6'],
  }

  ### Configure Apache frontend
  # Set up Apache
  # https://github.com/puppetlabs/puppetlabs-apache
  class{ 'apache': 
    default_vhost => false,
    mpm_module    => 'prefork', # for lam
    keepalive     => 'On',
    default_mods  => false,    # Disable large set of modules
  }

  # for lam
  include apache::mod::php
    
  apache::vhost { 'shibboleth-idp': 
    servername      => $::shibboleth_idp_URL,
    vhost_name      => $::shibboleth_idp_URL,
    port            => 80,
    docroot         => '/var/www/html',
    redirectmatch_regexp => '^(/(?!mod_status).*)$',
    redirectmatch_dest   => "https://$::shibboleth_idp_URL\$1",
    redirectmatch_status => 'permanent',
  }

  include apache::mod::proxy_ajp

  $ssl_apache_key="/etc/apache2/ssl/apache.key"
  $ssl_apache_crt="/etc/apache2/ssl/apache.crt"
  $ssl_apache_key_tmp="/vagrant/tmp/apache_idp.key"
  $ssl_apache_crt_tmp="/vagrant/tmp/apache_idp.crt"
  apache::vhost { 'shibboleth-idp-ssl':
    servername      => $::shibboleth_idp_URL,
    vhost_name      => $::shibboleth_idp_URL,
    ip              => $::ipaddress_eth1,
    port            => 443,
    docroot         => '/var/www/html',
    ssl             => true,
    ssl_cert        => $ssl_apache_crt,
    ssl_key         => $ssl_apache_key,
    proxy_dest      => 'ajp://localhost:8009',
  }  

  class { 'apache::mod::status':
    allow_from      => ['127.0.0.1','192.168.65.1','192.168.66.1','::1'],
    extended_status => 'On',
    status_path     => '/mod_status',
  }

  # Create a centralized self signed certificate for apache
  file { 'apache_key':
    path => $ssl_apache_key,
    ensure => link,
    target => $ssl_apache_key_tmp,
  }
  file { 'apache_crt':
    path => $ssl_apache_crt,
    ensure => link,
    target => $ssl_apache_crt_tmp,
  }
  file { '/etc/apache2/ssl/':
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => Package['apache2'],
    notify  => Exec['genapacheselfsigned']
  }

  exec { 'genapacheselfsigned':
    command     => "/usr/bin/openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ${ssl_apache_key_tmp} -out ${ssl_apache_crt_tmp} -subj \"/C=FR/ST=Bretagne/L=Rennes/O=vagrant/CN=$::shibboleth_idp_URL\"",
    user        => 'root',
    cwd         => '/etc/apache2/',
    creates     => $ssl_apache_key_tmp,
    notify      => Service['httpd'],
  }
}
