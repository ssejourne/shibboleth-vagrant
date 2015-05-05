#
class shibboleth-idp(
  $service_providers,      # { 'sp-title'  => 'sp-metadata-url' }
  $users,                  # { 'username' => 'password'        }
#  $version                 = '3.1.1',
  $version                 = '2.4.4',
  $idp_home                = '/opt/shibboleth-idp',
  $idp_hostname            = $::fqdn,
  $idp_entity_id_path      = '/idp/shibboleth',
  $keystore_password       = 'changeit',
  $port                    = '80',
  $status_page_allowed_ips = '192.168.66.1/32 127.0.0.1/32 ::1/128',
  $tomcat_home             = '/usr/share/tomcat6',
  $tomcat_user             = 'tomcat6',
  $tomcat_group            = 'tomcat6',
  $java_home       = '/usr/lib/jvm/java-7-openjdk-amd64',
){

  $idp_entity_id = "https://${idp_hostname}${idp_entity_id_path}"

  class { 'shibboleth-idp::prereqs':
    port => $port
  }

  class { 'shibboleth-idp::download':
    version => $version
  }

  class { 'shibboleth-idp::install':
    version                 => $version,
    idp_home                => $idp_home,
    status_page_allowed_ips => $status_page_allowed_ips,
    keystore_password       => $keystore_password,
    java_home               => $java_home
  }

  class { 'shibboleth-idp::tomcat_config':
    idp_home     => $idp_home,
    idp_version  => $version,
    users        => $users,
    tomcat_home  => $tomcat_home,
    tomcat_user  => $tomcat_user,
    tomcat_group => $tomcat_group
  }

  class { 'shibboleth-idp::shib_config':
    idp_home          => $idp_home,
    idp_entity_id     => $idp_entity_id,
    service_providers => $service_providers
  }

  Class['shibboleth-idp::prereqs'] ->
    Class['shibboleth-idp::download'] ->
    Class['shibboleth-idp::install'] ->
    Class['shibboleth-idp::tomcat_config'] ->
    Class['shibboleth-idp::shib_config']
}
