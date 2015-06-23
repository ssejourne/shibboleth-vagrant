#
class shibboleth_idp::download(
){
  if versioncmp($::shibboleth_idp::idp_version, '3.0.0') < 0 {
    $filename = "shibboleth-identityprovider-${::shibboleth_idp::idp_version}-bin.tar.gz"
  } else {
    $filename = "shibboleth-identity-provider-${::shibboleth_idp::idp_version}.tar.gz"
  }

  $remote_url = "http://shibboleth.net/downloads/identity-provider/${::shibboleth_idp::idp_version}/${filename}"

  exec { 'download-shibboleth':
    timeout => 0,
    command => "wget ${remote_url}",
    cwd     => $::shibboleth_idp::download_dir,
    creates => "${::shibboleth_idp::download_dir}/${filename}"
  }

  exec { 'unzip-shibboleth':
    command => "tar xvzf ${::shibboleth_idp::download_dir}/${filename}",
    cwd     => '/usr/local/src',
    creates => "/usr/local/src/shibboleth-${::shibboleth_idp::idp_string}-${::shibboleth_idp::idp_version}",
    require => Exec['download-shibboleth'],
  }
}
