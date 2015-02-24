class shibboleth-idp::shib_config(
  $idp_home,
  $idp_entity_id,
  $service_providers
) {
# Dirty hack for metadata file. Need to improve for multiple sp
  file { "${idp_home}/metadata/shibboleth-sp.vagrant.dev.xml":
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source => "puppet:///files/idp/shibboleth-sp.vagrant.dev.xml",
    notify  => Class['tomcat::service']
  }
  # use the ldap
  file { "${idp_home}/conf/login.config":
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source => "puppet:///files/idp/login.config",
    notify  => Class['tomcat::service']
  }
  file { "${idp_home}/conf/handler.xml":
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source => "puppet:///files/idp/handler.xml",
    notify  => Class['tomcat::service']
  }

  file { "${idp_home}/conf/relying-party.xml":
    owner   => 'root',
    group   => 'tomcat6',
    mode    => '0644',
    content => template('shibboleth-idp/relying-party.xml.erb'),
    notify  => Class['tomcat::service']
  }
  file { "${idp_home}/conf/attribute-resolver.xml":
    owner   => 'root',
    group   => 'tomcat6',
    mode    => '0644',
    content => template('shibboleth-idp/attribute-resolver.xml.erb'),
    notify  => Class['tomcat::service']
  }
  file { "${idp_home}/conf/attribute-filter.xml":
    owner   => 'root',
    group   => 'tomcat6',
    mode    => '0644',
    content => template('shibboleth-idp/attribute-filter.xml.erb'),
    notify  => Class['tomcat::service']
  }

}
