#
class profiles::haproxy {
  ## Hiera Lookup
  $vips = hiera('profiles::haproxy::vip_network_config')

  # Add repo for haproxy package
  case ($::osfamily) {
    'Debian': {
      include apt
      if ( $::lsbdistcodename == 'trusty' ) {
        include ::apt::backports
      } else {
        warning('Please check that haproxy >= 1.5')
      }
    }
    default: {
      fail("${::operatingsystem} not yet supported")
    }
  }

  # Set VIP
  create_resources( ::profiles::haproxy::configure_haproxy_vips, $vips)

  # Add collectd plugin for haproxy
  if defined('collectd') {
    collectd::plugin::python::module { 'haproxy':
      script_source => 'puppet:///files/haproxy/collectd-haproxy/haproxy.py',
      config        => { 'Socket' => '"/var/run/haproxy.sock"' },
      require       =>  Package['haproxy'],
    }
  }

  if ($::osfamily == 'Debian') {
    $haproxy_require = Class['::apt::backports']
  } else {
    $haproxy_require = undef
  }
  class { '::haproxy':
    require => $haproxy_require
  }

  # Create haproxy config file
  $haproxy_listen_services = hiera_hash('profiles::haproxy::listen_services', {})
  $haproxy_frontends       = hiera_hash('profiles::haproxy::frontends',       {})
  $haproxy_backends        = hiera_hash('profiles::haproxy::backends',        {})

  create_resources('::haproxy::listen',         $haproxy_listen_services)
  create_resources('::haproxy::frontend',       $haproxy_frontends)
  create_resources('::haproxy::backend',        $haproxy_backends)
}

