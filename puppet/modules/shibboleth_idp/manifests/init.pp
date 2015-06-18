# Class: shibboleth_idp
#
# This class installs Shibboleth Identity Provider 
#
class shibboleth_idp(
  $download_dir                   = $shibboleth_idp::params::download_dir,
  $idp_entity_id_path             = $shibboleth_idp::params::idp_entity_id_path,
  $idp_home                       = $shibboleth_idp::params::idp_home,
  $idp_hostname                   = $shibboleth_idp::params::idp_hostname,
  $idp_version                    = $shibboleth_idp::params::idp_version,
  $java_home                      = $shibboleth_idp::params::java_home,
  $java_version                   = $shibboleth_idp::params::java_version,
  $keystore_password              = $shibboleth_idp::params::keystore_password,
  $service_providers              = $shibboleth_idp::params::service_providers,
  $status_page_allowed_ips        = $shibboleth_idp::params::status_page_allowed_ips,
  $tomcat_catalina_base           = $shibboleth_idp::params::tomcat_catalina_base,
  $tomcat_group                   = $shibboleth_idp::params::tomcat_group,
  $tomcat_server_config_filename  = $shibboleth_idp::params::tomcat_server_config_filename,
  $tomcat_user                    = $shibboleth_idp::params::tomcat_user,
  $users                          = $shibboleth_idp::params::users,
) inherits shibboleth_idp::params {

  $idp_entity_id = "https://${idp_hostname}${idp_entity_id_path}"

  # TODO : passer ces variables dans params
  #  $_tomcat_package_name = 'tomcat6'
  $_tomcat_instance_name = 'idp'
  $_tomcat_service_name = "tomcat-${_tomcat_instance_name}"
  $_tomcat_server_name = $_tomcat_instance_name
  #$_tomcat_server_config = "${tomcat_catalina_base}/conf/${tomcat_server_config_filename}"
  $_tomcat_server_config = "${tomcat_catalina_base}/conf/server.xml"

  # Install Java
  class { 'java':
    distribution => 'jdk',
    version      => $java_version,
  }

  # Initiate tomcat
  class { 'tomcat':
    catalina_home    => $tomcat_catalina_base,
    user             => $tomcat_user,
    group            => $tomcat_group,
    #purge_connectors => true,
    #purge_realms     => true,
  }

  ###  # let's create a certificate for tomcat's TLS
  ###  # TODO : Use puppetlabs/java_ks instead
  $tomcat_cert_dname = "CN=${::shibboleth_idp_URL}, OU=vagrant.dev, O=vagrant, L=Rennes, S=Bretagne, C=FR"
  #exec { 'tomcat_genkeypair':
  #  command => "keytool -genkeypair -alias tomcat -keyalg RSA -keysize 2048 -dname '${_tomcat_cert_dname}' -storepass changeit -keypass changeit",
  #  user    => $tomcat_user,
  #  cwd     => $tomcat__catalina_base,
  #  creates => "${_tomcat__catalina_base}/.keystore"
  #}

  tomcat::instance { "${_tomcat_instance_name}":
    catalina_base => $tomcat_catalina_base,
    source_url    => 'http://www.eu.apache.org/dist/tomcat/tomcat-7/v7.0.62/bin/apache-tomcat-7.0.62.tar.gz'
  }->
  #Exec['tomcat_genkeypair']->
  tomcat::config::server { "${_tomcat_server_name}":
    catalina_base => $tomcat_catalina_base,
    server_config => $_tomcat_server_config,
    port          => '8005',
    shutdown      => 'SHUTDOWN'
  }->
###  tomcat::config::server::connector { 'default-https':
###    catalina_base         => $tomcat_catalina_base,
###    port                  => '8443',
###    protocol              => 'HTTP/1.1',
###    additional_attributes => {
###      'SSLEnabled'  => 'true',
###      'maxThreads'  => '150',
###      'scheme'      => 'https',
###      'secure'      => 'true',
###      'clientAuth'  => 'false',
###      'sslProtocol' => 'TLS'
###    },
###  }->
  tomcat::config::server::connector { "${_tomcat_server_name}-ajp":
    catalina_base         => $tomcat_catalina_base,
    server_config         => $_tomcat_server_config,
    port                  => '8009',
    protocol              => 'AJP/1.3',
    additional_attributes => {
#      'redirectPort'  => '8443',
      'enableLookups'     => 'false'
    },
  }->
  # Pb? bloque le demarrage
  tomcat::config::server::context { "${_tomcat_server_name}-context":
    catalina_base           => $tomcat_catalina_base,
    server_config           => $_tomcat_server_config,
    context_ensure          => present,
    doc_base                => "${idp_home}/war/idp.war",
    parent_service          => 'Catalina',
    parent_engine           => 'Catalina',
    parent_host             => 'localhost',
    additional_attributes   => {
      'privileged'          => 'true',
      'antiResourceLocking' => 'false',
      'antiJARLocking'      => 'false',
      'unpackWAR'           => 'false',
      'swallowOutput'       => 'true',
    },
  }->
  tomcat::config::server::tomcat_users { "${_tomcat_server_name}-users":
    catalina_base => $tomcat_catalina_base,
    # TODO use $users
    element_name  => 'shibadmin',
    password      => 'shibshib',
  }->
  #tomcat::config::server::realm { "${_tomcat_server_name}-realm":
  #  catalina_base => $tomcat_catalina_base,
  #  server_config => $_tomcat_server_config,
  #  class_name    => 'org.apache.catalina.realm.MemoryRealm',
  #  purge_realms  => true,
  #}->
  tomcat::config::server::valve { "${_tomcat_server_name}-valve":
    valve_ensure   => absent,
    catalina_base  => $tomcat_catalina_base,
    server_config  => $_tomcat_server_config,
    class_name     => 'org.apache.catalina.valves.AccessLogValve',
    parent_host    => 'localhost',
    parent_service => 'Catalina',
  }->
  class { 'shibboleth_idp::download': }->
  class { 'shibboleth_idp::install': }->
  class { 'shibboleth_idp::shib_config':
    tomcat_service_name => $_tomcat_service_name,
  }->
  tomcat::service { "${_tomcat_service_name}" :
    catalina_base => $tomcat_catalina_base,
    use_jsvc      => false,
    use_init      => false,
    #use_init          => true,
    #service_enable    => true,
    #service_name  => "${_tomcat_service_name}",
  }

}
