###############
### MONITOR ###
###############

# Configure the node now
node 'monitor.vagrant.dev' {
  Exec {
    path => '/usr/local/bin:/usr/bin:/usr/sbin:/bin'
  }

  include baseconfig

  class { 'graphite': 
    gr_max_updates_per_second => 100,
    gr_timezone               => 'Europe/Paris',
    secret_key                => 'vagrant',
    gr_enable_udp_listener    => true,
    gr_storage_schemas        => [
      {
        name       => 'carbon',
        pattern    => '^carbon\.',
        retentions => '1m:90d'
      },
      {
        name       => 'collectd',
        pattern    => '^collectd\.',
        retentions => '10s:1d,1m:7d,10m:2y'
      },
      {
        name       => 'default',
        pattern    => '.*',
        retentions => '1s:30m,1m:1d,5m:7y'
      }
    ],
  }

# Fix graphite for Django 1.6
  if $::osfamily == "Debian" {
    exec { "fix_graphite_django1.6":
      command => '/usr/bin/find /opt/graphite/webapp/graphite -iname "urls.py" -exec /bin/sed -i s/"from django.conf.urls.defaults import \*"/"from django.conf.urls import \*"/ {} \;',
      onlyif => "/bin/grep -r 'from django.conf.urls.defaults import' /opt/graphite/webapp/graphite",
      require => Class['graphite'],
    }
  }

}

