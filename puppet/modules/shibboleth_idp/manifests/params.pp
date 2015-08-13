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

  $idp_src_dir = "/usr/local/src"
}
