#
class shibboleth_idp::tomcat inherits shibboleth_idp::params {
  # Java runtime environment
  include ::java

  # Servlet container: Apache Tomcat
  case $::osfamily {
    'Debian': {
      include ::apt

      class { '::tomcat':
        catalina_home       => $::shibboleth_idp::catalina_home,
        install_from_source => false,
        purge_connectors    => true,
        purge_realms        => true,
      }
                                        
      ::tomcat::instance{ 'default':
        install_from_source => false,
        package_ensure      => $::shibboleth_idp::tomcat_package_ensure,
        package_name        => $::shibboleth_idp::tomcat_package_name,
      }

      ::tomcat::service { 'default':
        use_jsvc     => false,
        use_init     => true,
        service_name => $::shibboleth_idp::tomcat_package_name,
      }
    }
    default: {
      fail("Unsupported ${::osfamily}")
    }
  }

  # https://www.switch.ch/aai/guides/idp/installation/
  Tomcat::Instance['default']->
  ::tomcat::config::server{ 'default': }->
  ::tomcat::config::server::connector { 'default-ajp':
    port     => '8109',
    protocol => 'AJP/1.3',
  }->
  #  tomcat::config::server::connector { 'default-http':
  #  port             => '8080',
  #  connector_ensure => 'absent',
  #}->
  ::tomcat::config::server::host { 'default-localhost':
    host_ensure           => 'present',
    host_name             => 'localhost',
    app_base              => 'webapps',
    additional_attributes => {
      'unpackWARs'        => 'true',
      'autoDeploy'        => 'false'
    }
  }->
  Tomcat::Service['default']
}
