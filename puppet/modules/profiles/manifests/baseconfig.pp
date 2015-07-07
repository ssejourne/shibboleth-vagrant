# == Class: baseconfig
#
# Performs initial configuration
#
class profiles::baseconfig {
  case ($::osfamilly) {
    'Debian': {
      notice("apt: update before install a package")
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

  include ::timezone
  include ::ntp
  include ::collectd
  include ::collectd::plugin::cpu
  include ::collectd::plugin::load
  include ::collectd::plugin::memory
  include ::collectd::plugin::swap
  include ::collectd::plugin::disk
  include ::collectd::plugin::interface
  include ::collectd::plugin::write_graphite
  include ::sysctl::base
  #include ::os_hardening
}
