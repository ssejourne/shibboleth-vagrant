#
# Based on instructions at:
# https://wiki.shibboleth.net/confluence/display/SHIB2/IdPApacheTomcatPrepare
#
class shibboleth_idp::tomcat_config(
  $idp_home,
  $idp_version,
  $users,
  $tomcat_home,
  $tomcat_user,
  $tomcat_group,
  $tomcat_service_name
) {

  file { "${idp_home}/conf/users.xml":
    owner   => 'root',
    group   => $tomcat_group,
    mode    => '0644',
    content => template('shibboleth_idp/users.xml.erb')
  }

# to adapt for tomcat class
  file { '/etc/tomcat6/Catalina/localhost/idp.xml':
    owner   => $tomcat_user,
    group   => $tomcat_group,
    mode    => '0644',
    content => template('shibboleth_idp/idp.xml.erb'),
    notify  => Tomcat::Service[$tomcat_service_name]
  }

# Do not manage legacy versions
#  if !member(['2.4.3','3.0'],$idp_version) {
#    exec { 'endorse-xerces-and-xalan':
#      command => "[ -d ${idp_home}/lib/endorsed ]&&\
#(cp -r ${idp_home}/lib/endorsed ${tomcat_home}/ && \
#chown -R ${tomcat_user}:${tomcat_group} ${tomcat_home}/endorsed)||true",
#      creates => "${tomcat_home}/endorsed",
#      notify  => Class['tomcat::service']
#    }
#    warning("IdP version ${idp_version} : need to endorse xerces and xalan")
#  }
#  else {
#    notice("IdP version ${idp_version} : no need to endorse xerces and xalan")
#  }
}
