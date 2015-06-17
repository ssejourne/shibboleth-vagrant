#
class shibboleth_idp::install(
) {

  $shibboleth_src_dir = "/usr/local/src/shibboleth-identityprovider-${::shibboleth_idp::idp_version}"

  file { 'install.properties':
    path    =>
"${shibboleth_src_dir}/src/installer/resources/install.properties",
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => template('shibboleth_idp/install.properties.erb')
  }

  file { 'web.xml':
    path    => "${shibboleth_src_dir}/src/main/webapp/WEB-INF/web.xml",
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('shibboleth_idp/web.xml.erb')
  }

  exec { 'shibboleth-installer':
    command     => 'chmod u+x install.sh && ./install.sh',
    cwd         => $shibboleth_src_dir,
    user        => 'root',
    environment => "JAVA_HOME=${::shibboleth_idp::java_home}",
    creates     => "${::shibboleth_idp::idp_home}/war",
    require     => [
      File['install.properties'],
      File['web.xml']
    ]
  }

  # Allow tomcat to write where it needs to do stuff for us, 
  # like log and fetch metadata.
  file { [
    "${::shibboleth_idp::idp_home}/logs",
    "${::shibboleth_idp::idp_home}/metadata"
  ]:
    ensure  => directory,
    owner   => 'root',
    group   => $::shibboleth_idp::tomcat_group,
    mode    => '0775',
    require => Exec['shibboleth-installer']
  }
}
