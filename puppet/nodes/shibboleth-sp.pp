###################################
### Shibboleth SP + LDAP server ###
###################################

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

### 
  ### Add a test LDAP
  class { 'ldap::server':
    suffix  => $::ldap_suffix,
    rootdn  => "cn=$::ldap_admin,$::ldap_suffix",
    rootpw  => "$::ldap_admin_pw"
  }

  class { 'ldap::client':
    uri  => "${ldap_uri}",
    base => "${ldap_suffix}",
  }

  Class['ldap::server'] -> Class['ldap::client']

  # Install ldap-account-manager to play with LDAP
  package {'ldap-account-manager':
    ensure  => installed ,
    require => [Apache::Vhost['shibboleth-sp-ssl'],Class['ldap::client']],
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
    command   => "/usr/bin/ldapadd -D \"cn=${ldap_admin},${ldap_suffix}\" -w ${ldap_admin_pw} -f /etc/ldap/test_users.ldif",
    user      => 'openldap',
    require   => [File['/etc/ldap/test_users.ldif'],Package['ldap-utils']]
  }

### Shibboleth SP
  # Create self signed certificate for apache
  file { '/etc/apache2/ssl/':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    require => Package['apache2']
  }

  $ssl_apache_key="/etc/apache2/ssl/apache.key"
  $ssl_apache_crt="/etc/apache2/ssl/apache.crt"
  exec { 'genapacheselfsigned':
    command     => "/usr/bin/openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ${ssl_apache_key} -out ${ssl_apache_crt} -subj \"/C=FR/ST=Bretagne/L=Rennes/O=vagrant/CN=$::fqdn\"",
    user        => 'root',
    cwd         => '/etc/apache2/',
    creates     => $ssl_apache_key, 
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
    port            => 80,
    docroot         => '/var/www/html',
    redirect_status => 'permanent',
    redirect_dest    => "https://${::fqdn}/",
  }

  apache::vhost { 'shibboleth-sp-ssl':
    servername      => $::fqdn,
    vhost_name      => $::fqdn,
    port            => 443,
    docroot         => '/var/www/html',
    ssl             => true,
    ssl_cert        => $ssl_apache_crt,
    ssl_key         => $ssl_apache_key,
    aliases => [
      { alias       => '/lam',
        path        => '/usr/share/ldap-account-manager',
      }
    ],
    custom_fragment => '  UseCanonicalName On

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

