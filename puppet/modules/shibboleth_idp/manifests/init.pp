#
class shibboleth_idp (
  $catalina_home                = $shibboleth_idp::params::catalina_home,
  $idp_install_dir              = $shibboleth_idp::params::idp_install_dir,
  $idp_service_name             = $shibboleth_idp::params::idp_service_name,
  $idp_src_dir                  = $shibboleth_idp::params::idp_src_dir,
  $idp_status_page_allowed_ips  = $shibboleth_idp::params::idp_status_page_allowed_ips,
  $idp_version                  = $shibboleth_idp::params::idp_version,
  $ldap_admin                   = $shibboleth_idp::params::ldap_admin,
  $ldap_admin_pw                = $shibboleth_idp::params::ldap_admin_pw,
  $ldap_suffix                  = $shibboleth_idp::params::ldap_suffix,
  $ldap_uri                     = $shibboleth_idp::params::ldap_uri,
  $ldap_use_ssl                 = $shibboleth_idp::params::ldap_use_ssl,
  $tomcat_package_name          = $shibboleth_idp::params::tomcat_package_name,
  $tomcat_package_ensure        = $shibboleth_idp::params::tomcat_package_ensure,
) inherits shibboleth_idp::params {

  class {'shibboleth_idp::tomcat': }->
  class {'shibboleth_idp::download': }->
  class {'shibboleth_idp::config': }

  ::tomcat::service { 'default':
    use_jsvc     => false,
    use_init     => true,
    service_name => $::shibboleth_idp::tomcat_package_name,
  }
}
