class tomcat(
  $port              = 8080,
  $tomcat_monitor_ip = $::fqdn
){
  include tomcat::package

  class { 'tomcat::config':
    port              => $port,
    authbind          => ($port <= 1024),
    tomcat_monitor_ip => $tomcat_monitor_ip
  }

  include tomcat::service

  Class['tomcat::package'] ->
  Class['tomcat::config'] ->
    Class['tomcat::service'] ->
    Class['tomcat']
}
