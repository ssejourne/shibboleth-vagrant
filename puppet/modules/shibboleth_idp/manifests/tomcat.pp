#
class shibboleth_idp::tomcat inherits shibboleth_idp {
  # Java runtime environment
  include ::java

  # Servlet container: Apache Tomcat
  case $::osfamily {
    'Debian': {
      include ::apt

      class { '::tomcat':
        catalina_home       => $::shibboleth_idp::catalina_home,
        install_from_source => false,
        #purge_connectors    => true,
        purge_realms        => true,
      }
                                        
      ::tomcat::instance{ 'default':
        install_from_source => false,
        package_ensure      => $::shibboleth_idp::tomcat_package_ensure,
        package_name        => $::shibboleth_idp::tomcat_package_name,
      }
    }
    default: {
      fail("Unsupported ${::osfamily}")
    }
  }

  # https://www.switch.ch/aai/guides/idp/installation/
  ::tomcat::config::server{ 'default':
    require => ::Tomcat::Instance['default']
  }->
  ::tomcat::config::server::connector { 'default-ajp':
    port     => '8009',
    protocol => 'AJP/1.3',
  }->
  ::tomcat::config::server::connector { 'default-http':
    port             => '8080',
    connector_ensure => 'absent',
    notify           => ::Tomcat::Service['default']
  }
}
