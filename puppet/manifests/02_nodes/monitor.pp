###############
### MONITOR ###
###############

# Configure the node now
node 'monitor.vagrant.dev' {
  Exec {
    path => '/usr/local/bin:/usr/bin:/usr/sbin:/bin:/sbin'
  }

  include baseconfig

  class { 'graphite':
    gr_max_updates_per_second    => 100,
    gr_timezone                  => 'Europe/Paris',
    secret_key                   => 'vagrant',
    gr_enable_udp_listener       => true,
    gr_storage_schemas           => [
      {
        name       => 'carbon',
        pattern    => '^carbon\.',
        retentions => '1m:90d'
      },
      {
        name       => 'collectd',
        pattern    => '^collectd\.',
        retentions => '10s:1d,1m:7d,5m:1y'
      },
      {
        name       => 'servers',
        pattern    => '^servers\.',
        retentions => '10s:1d,1m:7d,5m:1y'
      },
      {
        name       => 'statsd',
        pattern    => '^stats\.',
        retentions => '10s:1d,1m:7d,5m:1y'
      },
      {
        name       => 'default',
        pattern    => '.*',
        retentions => '10s:1d,1m:7d,5m:1y'
      }
    ],
    gr_storage_aggregation_rules => {
      '00_min'         => {
        pattern => '\.min$',
        factor  => '0.1',
        method  => 'min'
      },
      '01_max'         => {
        pattern => '\.max$',
        factor  => '0.1',
        method  => 'max'
      },
      '02_count'       => {
        pattern => '\.count$',
        factor  => '0.1',
        method  => 'sum'
      },
      '03_lower'       => {
        pattern => '\.lower(_\d+)?$',
        factor  => '0.1',
        method  => 'min'
      },
      '04_upper'       => {
        pattern => '\.upper(_\d+)?$',
        factor  => '0.1',
        method  => 'max'
      },
      '05_sum'         => {
        pattern => '\.sum$',
        factor  => '0',
        method  => 'sum'
      },
      '06_gauges'      => {
        pattern => '^.*\.gauges\..*',
        factor  => '0',
        method  => 'last'
      },
      '99_default_avg' => {
        pattern => '.*',
        factor  => '0.5',
        method  => 'average'
      }
    },
  }

# Fix graphite for Django 1.6
  if $::osfamily == 'Debian' {
    exec { 'fix_graphite_django1.6':
      command => '/usr/bin/find /opt/graphite/webapp/graphite \
-iname "urls.py" -exec /bin/sed -i \
s/"from django.conf.urls.defaults import \*"/"from django.conf.urls import \*"\
/ {} \;',
      onlyif  => "/bin/grep -r 'from django.conf.urls.defaults \
import' /opt/graphite/webapp/graphite",
      require => Class['graphite'],
    }
  }

  ### Statsd
  include apt

  class { 'nodejs':
    manage_package_repo       => false,
    nodejs_dev_package_ensure => 'present',
    npm_package_ensure        => 'present',
    legacy_debian_symlinks    => true,
    require                   => Class['apt'],
  }

  class { 'statsd':
      backends                 => [ './backends/graphite'],
      graphiteHost             => 'localhost',
      node_module_dir          => '/usr/local/lib/node_modules',
      graphite_legacyNamespace => false,
      require                  => Class['nodejs'],
  }

  ### we need a java jdk for jmxtrans
  package {'default-jdk':
    ensure => installed,
  }

  ### JMXTRANS
  $jmxtrans_filename = 'jmxtrans_20121016-175251-ab6cfd36e3-1_all.deb'
  $jmxtrans_remote_url = "https://github.com/downloads/jmxtrans/jmxtrans/${jmxtrans_filename}"

  exec { 'download-jmxtrans':
    timeout => 0,
    command => "wget ${jmxtrans_remote_url}",
    cwd     => '/vagrant',
    creates => "/vagrant/${jmxtrans_filename}"
  }

  package {'jmxtrans':
    ensure   => installed,
    provider => dpkg,
    source   => "/vagrant/${jmxtrans_filename}",
    require  => [
  Package['default-jdk'],
  Exec['download-jmxtrans'],
    ],
  }

  service {'jmxtrans':
    ensure     => running,
    hasrestart => true,
    hasstatus  => true,
    require    => Package['jmxtrans'],
  }

  # TODO : manage a dynamic list of hosts/files
  exec { 'jmxtrans-json-files':
    command => 'cp /vagrant/puppet/files/monitor/jmxtrans/* /var/lib/jmxtrans/',
    user    => 'root',
    creates => '/var/lib/jmxtrans/shibboleth-idp1.vagrant.dev.json',
    require => Package['jmxtrans'],
    notify  => Service['jmxtrans'],
  }
}

