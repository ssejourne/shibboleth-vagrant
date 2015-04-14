class gatling(
  $version                 = '2.1.4',
){

  package { 'default-jdk': ensure => installed }

  class { 'gatling::install':
    version                 => $version,
  }
}
