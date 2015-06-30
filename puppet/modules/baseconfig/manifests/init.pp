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
  #package { [ 'vim-nox', 'curl' , 'ntp' ]: ensure => installed }

  ### We don't need the chef-client.
  service {'chef-client':
    ensure   => stopped,
  }

  # ### Set timezone (nice to have)
  #file { '/etc/timezone':
  #  ensure  => present,
  #  content => 'Europe/Paris\n',
  #  owner   => 'root',
  #  group   => 'root',
  #  mode    => '0644',
  #  notify  => Exec['set_mytimezone']
  #}
  #
  #exec { 'set_mytimezone':
  #  command => 'dpkg-reconfigure -f noninteractive tzdata',
  #  user    => 'root',
  #}
  #
  #File['/etc/timezone'] -> Exec['set_mytimezone']

  ### IMPROVE SYSTEM MEMORY MANAGEMENT ###
  # Do less swapping
  sysctl { 'vm.swappiness': value => '10' }
  sysctl { 'vm.dirty_ratio': value => '80' }
  sysctl { 'vm.dirty_background_ratio': value => '5' }

  ### GENERAL NETWORK SECURITY OPTIONS ###

  # Number of times SYNACKs for passive TCP connection.
  sysctl { 'net.ipv4.tcp_synack_retries': value => '2' }

  # Allowed local port range
  sysctl { 'net.ipv4.ip_local_port_range': value => '2000 65535' }

  # Protect Against TCP Time-Wait
  sysctl { 'net.ipv4.tcp_rfc1337': value => '1' }

  # Decrease the time default value for tcp_fin_timeout connection
  sysctl { 'net.ipv4.tcp_fin_timeout': value => '15' }

  # Decrease the time default value for connections to keep alive
  sysctl { 'net.ipv4.tcp_keepalive_time':   value => '300' }
  sysctl { 'net.ipv4.tcp_keepalive_probes': value => '5' }
  sysctl { 'net.ipv4.tcp_keepalive_intvl':  value => '15' }

  ### TUNING NETWORK PERFORMANCE ###

  # Default Socket Receive Buffer
  #sysctl { 'net.core.rmem_default': value => '31457280' }

  # Maximum Socket Receive Buffer
  sysctl { 'net.core.rmem_max': value => '16777216' }

  # Default Socket Send Buffer
  #sysctl { 'net.core.wmem_default': value => '31457280' }

  # Maximum Socket Send Buffer
  sysctl { 'net.core.wmem_max': value => '16777216' }

  # Increase number of incoming connections
  sysctl { 'net.core.somaxconn': value => '8096' }
  sysctl { 'net.ipv4.tcp_max_syn_backlog': value => '8096' }

  # Increase number of incoming connections backlog
  sysctl { 'net.core.netdev_max_backlog': value => '5000' }

  # Increase the maximum amount of option memory buffers
  sysctl { 'net.core.optmem_max': value => '25165824' }

  # Increase the maximum total buffer-space allocatable
  # This is measured in units of pages (4096 bytes)
  #sysctl { 'net.ipv4.tcp_mem': value => '65536 131072 262144' }
  #sysctl { 'net.ipv4.udp_mem': value => '65536 131072 262144' }

  # Increase the read-buffer space allocatable
  sysctl { 'net.ipv4.tcp_rmem':     value => '4096 12582912 16777216' }
  sysctl { 'net.ipv4.udp_rmem_min': value => '16384' }

  # Increase the write-buffer-space allocatable
  sysctl { 'net.ipv4.tcp_wmem':     value => '4096 12582912 16777216' }
  sysctl { 'net.ipv4.udp_wmem_min': value => '16384'}

  # Increase the tcp-time-wait buckets pool size to prevent simple DOS attacks
  sysctl { 'net.ipv4.tcp_max_tw_buckets': value => '1440000' }
  sysctl { 'net.ipv4.tcp_tw_recycle':     value => '1' }
  sysctl { 'net.ipv4.tcp_tw_reuse':       value => '1' }

  #
  sysctl { 'net.ipv4.tcp_slow_start_after_idle': value => '0' }
}
