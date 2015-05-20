###############
### GATLING ###
###############

# Configure the node now
node 'gatling.vagrant.dev' {
  Exec {
    path => '/usr/local/bin:/usr/bin:/usr/sbin:/bin'
  }

  include baseconfig

  ### Collectd

  class { '::collectd':
    purge        => true,
    recurse      => true,
    purge_config => true,
  }

  collectd::plugin { 'cpu': }
  collectd::plugin { 'load': }
  collectd::plugin { 'memory': }
  collectd::plugin { 'swap': }
  collectd::plugin { 'disk': }
  collectd::plugin { 'interface': }
  
  class { 'collectd::plugin::write_graphite':
    graphitehost => 'monitor.vagrant.dev',
  }

  include gatling
}

