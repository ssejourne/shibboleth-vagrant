#
class shibboleth_idp::download(
  $version
){
  $filename = "shibboleth-identityprovider-${version}-bin.tar.gz"
  $remote_url = "http://shibboleth.net/downloads/identity-provider/${version}/${filename}"

  exec { 'download-shibboleth':
    timeout => 0,
    command => "wget ${remote_url}",
    cwd     => '/vagrant',
    creates => "/vagrant/${filename}"
  }

  exec { 'unzip-shibboleth':
    command => "tar xvzf /vagrant/${filename}",
    cwd     => '/usr/local/src',
    creates => "/usr/local/src/shibboleth-identityprovider-${version}",
    require => [
      Exec['download-shibboleth']
    ]
  }
}
