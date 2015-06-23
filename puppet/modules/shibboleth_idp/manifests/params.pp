# Class: shibboleth_idp::params
#
# This class manages Shibboleth Identity Provider parameters
#
# Parameters :
# - 
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class shibboleth_idp::params {
  $ensure                         = 'present'
  $download_dir                   = '/usr/local/src'
  $idp_entity_id_path             = '/idp/shibboleth'
  $idp_home                       = '/opt/shibboleth-idp'
  $idp_hostname                   = $::fqdn
  $idp_version                    = '3.1.1'
  $java_home                      = '/usr/lib/jvm/default-java/'
  $java_version                   = 'latest'
  $keystore_password              = 'changeit'
  $service_name                   = 'shibboleth_idp'
  #  $service_providers,        # { 'sp-title'  => 'sp-metadata-url' }
  $service_providers              = undef
  $status_page_allowed_ips        = '192.168.66.1/32 127.0.0.1/32 ::1/128'
  $tomcat_catalina_base           = '/opt/tomcat'
  $tomcat_server_config_filename  = 'idp.xml'
  $tomcat_user                    = 'tomcat'
  $tomcat_group                   = 'tomcat'
  $tomcat_version                 = '8.0.23'
  $users                          = { 'shibadmin' => 'shibshib' }

  case $::osfamily {
    'RedHat', 'Amazon': {
      warning("Not tested with ${::osfamily}")
    }
    'Debian': {
      notice("Ok tested with ${::osfamily}")
    }
    default: {
      fail("Unsupported ${::osfamilyi}")
    }
  }
}
