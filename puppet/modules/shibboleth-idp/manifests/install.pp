#
class shibboleth-idp::install(
  $version,
  $idp_home,
  $keystore_password,
  $status_page_allowed_ips,
  $java_home
) {

  $shibboleth_src_dir = "/usr/local/src/shibboleth-identityprovider-${version}"

  file { 'install.properties':
    path    =>
"${shibboleth_src_dir}/src/installer/resources/install.properties",
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => template('shibboleth-idp/install.properties.erb')
  }

  file { 'web.xml':
    path    => "${shibboleth_src_dir}/src/main/webapp/WEB-INF/web.xml",
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('shibboleth-idp/web.xml.erb')
  }

  exec { 'shibboleth-installer':
    command     => 'chmod u+x install.sh && ./install.sh',
    cwd         => $shibboleth_src_dir,
    user        => 'root',
    environment => "JAVA_HOME=${java_home}",
    creates     => "${idp_home}/war",
    require     => [
      File['install.properties'],
      File['web.xml']
    ]
  }

  # Allow tomcat to write where it needs to do stuff for us, 
  # like log and fetch metadata.
  file { [
    "${idp_home}/logs",
    "${idp_home}/metadata"
  ]:
    ensure  => directory,
    owner   => 'root',
    group   => 'tomcat6',
    mode    => '0775',
    require => Exec['shibboleth-installer']
  }
}
