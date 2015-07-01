# == Class: baseconfig
#
# Performs initial configuration tasks for all Vagrant boxes.
#
class baseconfig {
  case ($::osfamilly) {
    'Debian': {
      Exec['apt-get-update'] -> Package <| |>

      exec { 'apt-get-update':
        command => 'apt-get update',
        timeout => 60,
        tries   => 3
      }
    }
  }

  Exec {
    path => '/usr/local/bin:/usr/bin:/usr/sbin:/bin'
  }

  ### We don't need the chef-client. (Vagrant box)
  service {'chef-client':
    ensure   => stopped,
  }
}
