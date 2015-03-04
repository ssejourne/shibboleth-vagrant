# == Class: baseconfig
#
# Performs initial configuration tasks for all Vagrant boxes.
#
class baseconfig {
  Exec['apt-get-update'] -> Package <| |>

  Exec {
    path => '/usr/local/bin:/usr/bin:/usr/sbin:/bin'
  }

  exec { 'apt-get-update':
    command => 'apt-get update',
    timeout => 60,
    tries   => 3
  }

### a few support packages
  package { [ 'vim-nox', 'curl' , 'ntp' ]: ensure => installed }

### Set timezone (nice to have)
  file { '/etc/timezone':
    ensure   => present,
    content  => 'Europe/Paris\n',
    owner    => 'root',
    group    => 'root',
    mode     => '0644',
    notify   => Exec['set_mytimezone']
  }

  exec { 'set_mytimezone':
    command   => 'dpkg-reconfigure -f noninteractive tzdata',
    user      => 'root',
  }

  File['/etc/timezone'] -> Exec['set_mytimezone']
}
