######################
### Shibboleth IdP ###
######################

node /^shibboleth-idp.*$/ {
  $shibboleth_idp_URL = hiera('shibboleth_idp_URL')

  #  hiera_include('classes')

  # include baseconfig

  info("${::hostname} is ${::operatingsystem} with role ${::role}")

  ### Collectd
#  class { 'collectd::plugin::apache':
#    instances => {
#      'apache80' => {
#        'url' => 'http://localhost/mod_status?auto',
#      },
#    },
#  }

  ### The IdP is a LDAP client
  class { 'ldap::client':
    uri  => $ldap_uri,
    base => $ldap_suffix,
  }

  ### Configure Apache frontend
  # https://github.com/puppetlabs/puppetlabs-apache
  class{ 'apache':
    default_vhost => false,
    mpm_module    => 'prefork', # for lam
    keepalive     => 'On',
    default_mods  => false,    # Disable large set of modules
  }

  include apache::mod::alias
  apache::vhost { 'shibboleth-idp':
    servername           => $shibboleth_idp_URL,
    vhost_name           => $shibboleth_idp_URL,
    port                 => 80,
    docroot              => '/var/www/html',
    redirectmatch_regexp => '^(/(?!mod_status).*)$',
    redirectmatch_dest   => "https://${shibboleth_idp_URL}\$1",
    redirectmatch_status => 'permanent',
  }

  include apache::mod::proxy
  include apache::mod::proxy_ajp

  $ssl_apache_key='/etc/apache2/ssl/apache.key'
  $ssl_apache_crt='/etc/apache2/ssl/apache.crt'
  $ssl_apache_key_tmp='/vagrant/tmp/apache_idp.key'
  $ssl_apache_crt_tmp='/vagrant/tmp/apache_idp.crt'
  apache::vhost { 'shibboleth-idp-ssl':
    servername      => $shibboleth_idp_URL,
    ip              => $::ipaddress_eth1,
    port            => 443,
    docroot         => '/var/www/html',
    ssl             => true,
    ssl_cipher      => 'HIGH:MEDIUM:!aNULL:!kRSA:!MD5:!RC4',
    ssl_cert        => $ssl_apache_crt,
    ssl_chain       => $ssl_apache_crt,
    ssl_key         => $ssl_apache_key,
    custom_fragment => '
ProxyPass /idp ajp://localhost:8009/idp retry=5
<Proxy ajp://localhost:8009>
    Require all granted
</Proxy>
'
  }

  class { 'apache::mod::status':
    allow_from      => ['127.0.0.1','192.168.65.1','192.168.66.1','::1'],
    extended_status => 'On',
    status_path     => '/mod_status',
  }

  # Create a centralized self signed certificate for apache
  file { 'apache_key':
    ensure => link,
    path   => $ssl_apache_key,
    target => $ssl_apache_key_tmp,
  }
  file { 'apache_crt':
    ensure => link,
    path   => $ssl_apache_crt,
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
    command => "/usr/bin/openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ${ssl_apache_key_tmp} -out ${ssl_apache_crt_tmp} -subj \"/C=FR/ST=Bretagne/L=Rennes/O=vagrant/CN=${shibboleth_idp_URL}\"",
    user    => 'root',
    cwd     => '/etc/apache2/',
    creates => $ssl_apache_key_tmp,
    notify  => Service['httpd'],
  }

  class { 'shibboleth_idp':
    idp_install_dir             => '/opt/shibboleth-idp',
    idp_service_name            => $shibboleth_idp_URL,
    idp_status_page_allowed_ips => hiera('idp_status_page_allowed_ips'),
    ldap_admin                  => hiera('profiles::ldap::ldap_admin'),
    ldap_admin_pw               => hiera('profiles::ldap::ldap_admin_pw'),
    ldap_suffix                 => hiera('profiles::ldap::ldap_suffix'),
    ldap_uri                    => hiera('profiles::ldap::ldap_uri'),
    ldap_use_ssl                => hiera('profiles::ldap::ldap_use_ssl'),
  }
}
