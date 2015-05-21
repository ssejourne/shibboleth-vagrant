#
class shibboleth_idp(
  $idp_hostname            = $::fqdn,
  $service_providers,      # { 'sp-title'  => 'sp-metadata-url' }
  $users,                  # { 'username' => 'password'        }
  $status_page_allowed_ips = '192.168.66.1/32 127.0.0.1/32 ::1/128',
#  $version                 = '3.1.1',
  $version                 = '2.4.4',
  $idp_home                = '/opt/shibboleth-idp',
  $idp_entity_id_path      = '/idp/shibboleth',
  $keystore_password       = 'changeit',
  $port                    = '80',
  $catalina_base           = undef,
  $tomcat_service_name     = 'tomcat',
  $tomcat_user             = 'tomcat',
  $tomcat_group            = 'tomcat',
  $java_home		   = undef,
){

  $idp_entity_id = "https://${idp_hostname}${idp_entity_id_path}"

  class { 'shibboleth_idp::download': }

  class { 'shibboleth_idp::install':
    version                 => $version,
    idp_home                => $idp_home,
    status_page_allowed_ips => $status_page_allowed_ips,
    keystore_password       => $keystore_password,
    tomcat_group            => $tomcat_group,
    java_home               => $java_home
  }

  class { 'shibboleth_idp::shib_config':
    idp_home             => $idp_home,
    tomcat_service_name  => $tomcat_service_name,
    tomcat_group         => $tomcat_group,
  }

  class { 'shibboleth_idp::tomcat_config':
    idp_home            => $idp_home,
    idp_version         => $version,
    users               => $users,
    tomcat_home         => $catalina_base,
    tomcat_user         => $tomcat_user,
    tomcat_group        => $tomcat_group,
    tomcat_service_name => $tomcat_service_name
  }

  Class['shibboleth_idp::download'] ->
    Class['shibboleth_idp::install'] ->
    Class['shibboleth_idp::shib_config'] ->
    Class['shibboleth_idp::tomcat_config']

}
