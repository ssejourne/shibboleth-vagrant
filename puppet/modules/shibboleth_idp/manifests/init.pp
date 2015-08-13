#
class shibboleth_idp (
  $catalina_home          = $shibboleth_idp::params::catalina_home,
  $idp_version            = $shibboleth_idp::params::idp_version,
  $idp_src_dir            = $shibboleth_idp::params::idp_src_dir,
  $tomcat_package_name    = $shibboleth_idp::params::tomcat_package_name,
  $tomcat_package_ensure  = $shibboleth_idp::params::tomcat_package_ensure,
) inherits shibboleth_idp::params {

  class {'shibboleth_idp::download': }->
  class {'shibboleth_idp::install': }
}
