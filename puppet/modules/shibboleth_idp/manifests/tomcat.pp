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

  # Tomcat7 pb workaround (http://shibboleth.1660669.n2.nabble.com/IDP-metadata-in-3-0-td7610819.html)
  if ($::shibboleth_idp::tomcat_package_name == 'tomcat7') {
    augeas {'web.xml':
      lens    => 'Xml.lns',
      incl    => "${::shibboleth_idp::catalina_home}/conf/web.xml",
      changes => [
        "set /files${::shibboleth_idp::catalina_home}/conf/web.xml/web-app/servlet[servlet-name/#text='jsp']/init-param[./param-name/#text = 'compilerSourceVM']/param-name/#text 'compilerSourceVM'",
        "set /files${::shibboleth_idp::catalina_home}/conf/web.xml/web-app/servlet[servlet-name/#text='jsp']/init-param[./param-name/#text = 'compilerSourceVM']/param-value/#text '1.7'",
        "set /files${::shibboleth_idp::catalina_home}/conf/web.xml/web-app/servlet[servlet-name/#text='jsp']/init-param[./param-name/#text = 'compilerTargetVM']/param-name/#text 'compilerTargetVM'",
        "set /files${::shibboleth_idp::catalina_home}/conf/web.xml/web-app/servlet[servlet-name/#text='jsp']/init-param[./param-name/#text = 'compilerTargetVM']/param-value/#text '1.7'",
      ],
      #      onlyif  => "match /files/${::shibboleth_idp::catalina_home}/conf/web.xml/web-app/servlet[servlet-name/#text='jsp']/init-param/param-name/#text not_include 'compilerSourceVM'",
      require => ::Tomcat::Instance['default'],
      notify  => ::Tomcat::Service['default']
    }
  }
}
