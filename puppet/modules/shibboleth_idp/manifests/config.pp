# Freely adapted from https://www.switch.ch/aai/guides/idp/installation/idp-install.sh
class shibboleth_idp::config inherits shibboleth_idp {
  if ! defined(Package['openssl']) {
    package {'openssl':
      ensure => installed,
    }
  }

  exec {'create_credentials.properties':
    command => "echo \"idp.sealer.password = \$(openssl rand -base64 12)\" > credentials.properties",
    cwd     => "${shibboleth_idp::download::idp_src_fullpath}",
    creates => "${shibboleth_idp::download::idp_src_fullpath}/credentials.properties",
    require => Package['openssl']
  }->
  file {'credentials.properties':
    ensure => file,
    path   => "${shibboleth_idp::download::idp_src_fullpath}/credentials.properties",
    mode   => '0600'
  }

  file {'temp.properties':
    ensure  => file,
    path    => "${shibboleth_idp::download::idp_src_fullpath}/temp.properties",
    content => template('shibboleth_idp/temp.properties.erb'),
    mode    => '0644',
  }

  # TODO : need to get JAVA_HOME...
  exec {'shib_run_installer':
    command     => "${shibboleth_idp::download::idp_src_fullpath}/bin/install.sh \
    -Didp.relying.party.present= \
    -Didp.src.dir=. \
    -Didp.target.dir=${shibboleth_idp::idp_install_dir} \
    -Didp.merge.properties=temp.properties \
    -Didp.sealer.password=\$(cut -d \" \" -f3 <credentials.properties) \
    -Didp.keystore.password= \
    -Didp.conf.filemode=644 \
    -Didp.host.name=${shibboleth_idp::idp_service_name} \
    -Didp.scope=${shibboleth_idp::idp_service_name}",
    environment => "JAVA_HOME=/usr/lib/jvm/default-java",
    cwd         => "${shibboleth_idp::download::idp_src_fullpath}",
    creates     => "${shibboleth_idp::idp_install_dir}",
    require     => [ File['credentials.properties'], File['temp.properties'] ]
  }->
  exec {'copy_credentials':
    command => "cp ${shibboleth_idp::download::idp_src_fullpath}/credentials.properties ${shibboleth_idp::idp_install_dir}/conf \
    && chown ${shibboleth_idp::tomcat_package_name} ${shibboleth_idp::idp_install_dir}/conf/credentials.properties",
    creates => "${shibboleth_idp::idp_install_dir}/conf/credentials.properties"
  }

  exec {'shib_create_ss_certifs':
    command     => "${shibboleth_idp::download::idp_src_fullpath}/bin/keygen.sh --lifetime 3 \
    --certfile ${shibboleth_idp::idp_install_dir}/credentials/idp.crt \
    --keyfile ${shibboleth_idp::idp_install_dir}/credentials/idp.key \
    --hostname ${shibboleth_idp::idp_service_name} \
    --uriAltName https://${shibboleth_idp::idp_service_name}/idp/shibboleth",
    environment => "JAVA_HOME=/usr/lib/jvm/default-java",
    cwd         => "${shibboleth_idp::download::idp_src_fullpath}",
    creates     => "${shibboleth_idp::idp_install_dir}/credentials/idp.key",
    require     => Exec['shib_run_installer']
  }->
  file {
    'idp.key':
      ensure => file,
      path   => "${shibboleth_idp::idp_install_dir}/credentials/idp.key",
      owner  => "${shibboleth_idp::tomcat_package_name}",
      mode   => '0600';

    'sealer.jks':
      ensure => file,
      path   => "${shibboleth_idp::idp_install_dir}/credentials/sealer.jks",
      owner  => "${shibboleth_idp::tomcat_package_name}";

    'sealer.kver':
      ensure => file,
      path   => "${shibboleth_idp::idp_install_dir}/credentials/sealer.kver",
      owner  => "${shibboleth_idp::tomcat_package_name}";

    'metada':
      ensure => directory,
      path   => "${shibboleth_idp::idp_install_dir}/metadata",
      owner  => "${shibboleth_idp::tomcat_package_name}";

    'logs':
      ensure => directory,
      path   => "${shibboleth_idp::idp_install_dir}/logs",
      owner  => "${shibboleth_idp::tomcat_package_name}";
  }

  file {'ldap.properties':
    ensure  => file,
    path    => "${shibboleth_idp::idp_install_dir}/conf/ldap.properties",
    content => template('shibboleth_idp/ldap.properties.erb'),
    mode    => 0644,
    require => Exec['shib_run_installer'],
    notify  => ::Tomcat::Service['default'],
  }

  file {'access-control.xml':
    ensure  => file,
    path    => "${shibboleth_idp::idp_install_dir}/conf/access-control.xml",
    content => template('shibboleth_idp/access-control.xml.erb'),
    mode    => 0644,
    require => Exec['shib_run_installer'],
    notify  => ::Tomcat::Service['default'],
  }

  file {'attribute-resolver-ldap.xml':
    ensure  => file,
    path    => "${shibboleth_idp::idp_install_dir}/conf/attribute-resolver-ldap.xml",
    content => template('shibboleth_idp/attribute-resolver-ldap.xml.erb'),
    mode    => 0644,
    require => Exec['shib_run_installer'],
    notify  => ::Tomcat::Service['default'],
  }

  augeas {'services.xml':
    lens    => 'Xml.lns',
    incl    => "${shibboleth_idp::idp_install_dir}/conf/services.xml",
    changes => "set /files${shibboleth_idp::idp_install_dir}/conf/services.xml/beans/util:list[4]/value/#text \"%{idp.home}/conf/attribute-resolver-ldap.xml\"",
    require => Exec['shib_run_installer'],
    notify  => ::Tomcat::Service['default'],
  }

  file {'idp.xml':
    ensure => file,
    path   => "${::shibboleth_idp::catalina_home}/conf/Catalina/localhost/idp.xml",
    content   => "<!-- This file is managed by Puppet -->
<Context docBase=\"/opt/shibboleth-idp/war/idp.war\"
    unpackWAR=\"false\"
    swallowOutput=\"true\">
  <Manager pathname=\"\" />
</Context>
",
    mode    => '0644',
    require => [ Exec['shib_run_installer'], ::Tomcat::Instance['default'] ],
    notify  => ::Tomcat::Service['default'],
  }

  # Install JSP Standard Tag Library if we want status page
  if ($idp_status_page) {
    exec{'download-jstl':
      command       => 'curl -O https://repo1.maven.org/maven2/jstl/jstl/1.2/jstl-1.2.jar',
      cwd           => "${shibboleth_idp::idp_install_dir}/edit-webapp/WEB-INF/lib",
      creates       => "${shibboleth_idp::idp_install_dir}/edit-webapp/WEB-INF/lib/jstl-1.2.jar",
      require => Exec['shib_run_installer'],
    }->
    exec {'rebuild-idp-jstl':
      command     => "${shibboleth_idp::idp_install_dir}/bin/build.sh -Didp.target.dir=${shibboleth_idp::idp_install_dir}",
      environment => ['JAVACMD=/usr/bin/java'],
      cwd         => "${shibboleth_idp::idp_install_dir}",
      creates     => "${shibboleth_idp::idp_install_dir}/webapp/WEB-INF/lib/jstl-1.2.jar",
      notify      => ::Tomcat::Service['default'],
    }
  }

  # Configure metadata for the sp
  exec {'get_sp_metadata':
    command => "wget -q --no-check-certificate -O ${shibboleth_idp::idp_service_providers}.xml https://${shibboleth_idp::idp_service_providers}/Shibboleth.sso/Metadata",
    cwd     => "${shibboleth_idp::idp_install_dir}/metadata",
    creates => "${shibboleth_idp::idp_install_dir}/metadata/${shibboleth_idp::idp_service_providers}.xml",
    require => Exec['shib_run_installer'],
    notify  => ::Tomcat::Service['default'],
  }->
  augeas {'metadata-providers.xml':
    lens    => 'Xml.lns',
    incl    => "${shibboleth_idp::idp_install_dir}/conf/metadata-providers.xml",
    changes => [
      "set /files${shibboleth_idp::idp_install_dir}/conf/metadata-providers.xml/MetadataProvider/MetadataProvider[./#attribute/id = \"${shibboleth_idp::idp_service_providers}\"]/#attribute/id \"${shibboleth_idp::idp_service_providers}\"",
      "set /files${shibboleth_idp::idp_install_dir}/conf/metadata-providers.xml/MetadataProvider/MetadataProvider[./#attribute/id = \"${shibboleth_idp::idp_service_providers}\"]/#comment 'This entry is managed by Puppet'",
      "set /files${shibboleth_idp::idp_install_dir}/conf/metadata-providers.xml/MetadataProvider/MetadataProvider[./#attribute/id = \"${shibboleth_idp::idp_service_providers}\"]/#attribute/xsi:type 'FilesystemMetadataProvider'",
      "set /files${shibboleth_idp::idp_install_dir}/conf/metadata-providers.xml/MetadataProvider/MetadataProvider[./#attribute/id = \"${shibboleth_idp::idp_service_providers}\"]/#attribute/metadataFile \"${shibboleth_idp::idp_install_dir}/metadata/${shibboleth_idp::idp_service_providers}.xml\"",
    ],
    require => Exec['shib_run_installer'],
    notify  => ::Tomcat::Service['default'],
  }

}
