# Class: shibboleth_idp::params
#
# This class manages Shibboleth IdP parameters.
#
# Parameters:
class shibboleth_idp::params {
  # Tomcat
  $tomcat_package_ensure = 'present'

  case $::osfamily {
    'Debian': {
      $tomcat_package_name = 'tomcat7'
      $catalina_home = "/var/lib/${tomcat_package_name}"
    }
    default: {
      fail("Unsupported ${::osfamily}")
    }
  }

  # IdP
  $idp_version = '3.1.2'

  ## Where to put sources, and where to install IdP
  $idp_src_dir = '/usr/local/src'
  $idp_install_dir = '/opt/shibboleth-idp'

  ## IdP service name (required)
  $idp_service_name = 'idp.example.org'

  ## Do we want idp status page (require JSP Standard Tag Library)
  $idp_status_page = false
  $idp_status_page_allowed_ips = "'127.0.0.1/32', '::1/128'"

  # Ldap
  $ldap_admin = 'admin'
  $ldap_admin_pw = 'admin'
  $ldap_suffix = 'dc=exemple,dc=org'
  $ldap_uri = 'ldap://127.0.0.1'
  $ldap_use_ssl = 'false'

}
