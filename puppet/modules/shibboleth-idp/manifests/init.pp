class shibboleth-idp(
  $service_providers,      # { 'sp-title'  => 'sp-metadata-url' }
  $users,                  # { 'username' => 'password'        }
  $version                 = '2.4.0',
  $idp_home                = '/opt/shibboleth-idp',
  $keystore_password       = 'changeit',
  $port                    = '80',
  $status_page_allowed_ips = '192.168.66.1/32 127.0.0.1/32 ::1/128',
  $tomcat_home             = '/usr/share/tomcat6',
  $idp_entity_id           = "https://${fqdn}/idp/shibboleth",
){

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
    keystore_password       => $keystore_password
  }

  class { 'shibboleth-idp::tomcat_config':
    idp_home    => $idp_home,
    users       => $users,
    tomcat_home => $tomcat_home,
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
