###############
### MONITOR ###
###############

$jmx_shib_objects = [
  {
    'name'                             => 'java.lang:type=Memory',
    'resultAlias'                      => 'Memory',
    'attrs'                            => {
      'HeapMemoryUsage'                => {},
      'NonHeapMemoryUsage'             => {},
      'ObjectPendingFinalizationCount' => {}
    },
  },
  {
    'name'                      => 'java.lang:type=Threading',
    'resultAlias'               => 'Threads',
    'attrs'                     => {
      'DaemonThreadCount'       => {},
      'PeakThreadCount'         => {},
      'CurrentThreadCpuTime'    => {},
      'CurrentTheeadUserTime'   => {},
      'ThreadCount'             => {},
      'TotalStartedThreadCount' => {}
    },
  },
  {
    'name'              => 'java.lang:type=GarbageCollector,name=Copy',
    'resultAlias'       => 'GCCopy',
    'attrs'             => {
      'CollectionCount' => {},
      'CollectionTime'  => {}
    },
  },
  {
    'name'              => 'java.lang:type=GarbageCollector,name=MarkSweepCompact',
    'resultAlias'       => 'GCCMS',
    'attrs'             => {
    'CollectionCount' => {},
    'CollectionTime'  => {}
    },
  }
]

define create_jmxtrans_config {
  $jmx_host = $name

  jmxtrans::metrics { "${jmx_host}":
    jmx                  => "${jmx_host}:1105",
    graphite             => '127.0.0.1:2003',
    graphite_root_prefix => 'shib',
    objects              => $::jmx_shib_objects,
  }
}

# Configure the node now
node /^monitor.*$/ {
  Exec {
    path => '/usr/local/bin:/usr/bin:/usr/sbin:/bin:/sbin'
  }

  $download_dir=hiera('download_dir')

  hiera_include('classes')

  include baseconfig

  info("${::hostname} is ${::operatingsystem} with role ${::role}")

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
  $jmxtrans_version = '250'
  $jmxtrans_remote_url = "http://central.maven.org/maven2/org/jmxtrans/jmxtrans/${jmxtrans_version}/jmxtrans-${jmxtrans_version}.deb"
  $jmxtrans_filename = "jmxtrans-${jmxtrans_version}.deb"
  #$jmxtrans_filename = 'jmxtrans_20121016-175251-ab6cfd36e3-1_all.deb'
  #$jmxtrans_remote_url = "https://github.com/downloads/jmxtrans/jmxtrans/${jmxtrans_filename}"

  exec { 'download-jmxtrans':
    timeout => 0,
    command => "wget ${jmxtrans_remote_url}",
    cwd     => $download_dir,
    creates => "/${download_dir}/${jmxtrans_filename}"
  }->
  package {"jmxtrans-${jmxtrans_version}":
    ensure   => installed,
    provider => 'dpkg',
    source   => "/${download_dir}/${jmxtrans_filename}",
    require  => [
      Package['default-jdk'],
    ],
    before   => Class['jmxtrans'],
  }#->
  #service {"jmxtrans-${jmxtrans_version}":
  #  ensure     => running,
  #  hasrestart => true,
  #  hasstatus  => true,
  #}

  # TODO : manage a dynamic list of hosts/files
  $jmxtrans_host_list = hiera('idp_servers')
  
#  jmxtrans::metrics { 'shibboleth-idp1.vagrant.dev':
#    jmx                  => 'shibboleth-idp1.vagrant.dev:1105',
#    graphite             => '127.0.0.1:2003',
#    graphite_root_prefix => 'shib',
#    objects              => $jmx_shib_objects,
#  }
#
#  jmxtrans::metrics { 'shibboleth-idp2.vagrant.dev':
#    jmx                  => 'shibboleth-idp1.vagrant.dev:1105',
#    graphite             => '127.0.0.1:2003',
#    graphite_root_prefix => 'shib',
#    objects              => $jmx_shib_objects,
#  }
  
 create_jmxtrans_config { $jmxtrans_host_list:; }

}

