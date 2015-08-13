#
# to configure VIPs
define profiles::haproxy::configure_haproxy_vips($interface, $address) {
  notice ("configure VIP on interface ${interface} with IP ${address}")

  exec { "conf_vip_${address}":
    command => "/sbin/ifconfig ${interface} ${address}",
    user    => 'root',
    unless  => "/sbin/ifconfig -a | grep ${address} /dev/null",
    notify  => Service['haproxy']
  }
}

