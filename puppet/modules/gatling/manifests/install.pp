class gatling::install(
  $version,
) {

  $filename = "gatling-${version}.zip"
  $remote_url = "http://goo.gl/o14jQg"

  package { 'unzip': ensure => installed }

  exec { 'download-gatling':
    timeout => 0,
    command => "wget ${remote_url} -O ${filename}",
    cwd     => '/vagrant',
    creates => "/vagrant/${filename}"
  } -> 
  exec { 'unzip-gatling':
    command => "unzip /vagrant/${filename}",
    cwd     => "/opt",
  }

}
