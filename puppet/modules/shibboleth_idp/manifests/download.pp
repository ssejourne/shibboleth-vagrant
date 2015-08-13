class shibboleth_idp::download(
) {
  if versioncmp($::shibboleth_idp::idp_version, '3.0.0') < 0 {
    $idp_pkg_string = 'shibboleth-identityprovider'
    $filename = "${idp_pkg_string}-${::shibboleth_idp::idp_version}-bin.tar.gz"
  } else {
    $idp_pkg_string = 'shibboleth-identity-provider'
    $filename = "${idp_pkg_string}-${::shibboleth_idp::idp_version}.tar.gz"
  }
                          
  $remote_url = "http://shibboleth.net/downloads/identity-provider/${::shibboleth_idp::idp_version}/${filename}"

  package { 'wget':
    ensure => 'present'
  }

  package { 'tar':
    ensure => 'present'
  }

  exec { 'download-shibboleth':
    timeout => 0,
    command => "wget ${remote_url}",
    cwd     => $::shibboleth_idp::idp_src_dir,
    creates => "${::shibboleth_idp::idp_src_dir}/${filename}",
    require => Package['wget']
  }->
  exec { 'unzip-shibboleth':
    command => "tar xvzf ${::shibboleth_idp::idp_src_dir}/${filename}",
    cwd     => $::shibboleth_idp::idp_src_dir,
    creates => "${::shibboleth_idp::idp_src_dir}/${idp_pkg_string}-${::shibboleth_idp::idp_version}",
    require => Package['tar']
  }
}
