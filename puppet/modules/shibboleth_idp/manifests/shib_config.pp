#
class shibboleth_idp::shib_config(
  $tomcat_service_name,
) {
# Dirty hack for metadata file. Need to improve for multiple sp
  file { "${shibboleth_idp::idp_home}/metadata/shibboleth-sp.vagrant.dev.xml":
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => 'puppet:///files/idp/shibboleth-sp.vagrant.dev.xml',
    notify => Tomcat::Service[$tomcat_service_name]
  }
  # use the ldap
  file { "${shibboleth_idp::idp_home}/conf/login.config":
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('shibboleth_idp/login.config.erb'),
    notify  => Tomcat::Service[$tomcat_service_name]
  }
  file { "${shibboleth_idp::idp_home}/conf/handler.xml":
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('shibboleth_idp/handler.xml.erb'),
    notify  => Tomcat::Service[$tomcat_service_name]
  }

  file { "${shibboleth_idp::idp_home}/conf/relying-party.xml":
    owner   => 'root',
    group   => $shibboleth_idp::tomcat_group,
    mode    => '0644',
    content => template('shibboleth_idp/relying-party.xml.erb'),
  }
  file { "${shibboleth_idp::idp_home}/conf/attribute-resolver.xml":
    owner   => 'root',
    group   => $shibboleth_idp::tomcat_group,
    mode    => '0644',
    content => template('shibboleth_idp/attribute-resolver.xml.erb'),
    notify  => Tomcat::Service[$tomcat_service_name]
  }
  file { "${shibboleth_idp::idp_home}/conf/attribute-filter.xml":
    owner   => 'root',
    group   => $shibboleth_idp::tomcat_group,
    mode    => '0644',
    content => template('shibboleth_idp/attribute-filter.xml.erb'),
    notify  => Tomcat::Service[$tomcat_service_name]
  }

}
