# 
class profiles::haproxy {
  include ::haproxy

  ### Collectd
  if defined('collectd') {
    collectd::plugin::python::module { 'haproxy':
      script_source => 'puppet:///files/haproxy/collectd-haproxy/haproxy.py',
      config        => {
        'Socket' => '"/var/run/haproxy.sock"',
      },
      require       => Package['haproxy'],
    }
  }

  case ($::operatingsystem) {
    'Ubuntu': {
      $haproxy_repo = hiera('haproxy_repo')
      $haproxy_repo_name = hiera('haproxy_repo_name')
      exec {'add-apt-haproxy':
        command => "/usr/bin/add-apt-repository -y ${haproxy_repo}",
        user    => 'root',
        creates => "/etc/apt/sources.list.d/${haproxy_repo_name}.list",
        before  => Package['haproxy'],
      }
    }
    default: {
      fail("${::operatingsystem} not yet supported")
    }
  }

  $haproxy_listen_services = hiera_hash('haproxy::listen_services', {})
  $haproxy_frontends       = hiera_hash('haproxy::frontends',       {})
  $haproxy_backends        = hiera_hash('haproxy::backends',        {})

  create_resources('::haproxy::listen',         $haproxy_listen_services)
  create_resources('::haproxy::frontend',       $haproxy_frontends)
  create_resources('::haproxy::backend',        $haproxy_backends)
                                                                                                                                                            info('haproxy configuration is in load-balancer.yaml. Need to be modified if nodes are added or deleted.')
}

