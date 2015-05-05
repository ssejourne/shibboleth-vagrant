#
class tomcat::service {
  service { 'tomcat6':
    ensure     => running,
    hasrestart => true,
    subscribe  => Class['tomcat::config']
  }
}
