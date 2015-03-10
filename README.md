# Shibboleth Vagrant

Get an instance of [Shibboleth](https://shibboleth.net/products/identity-provider.html) SP and Idp up and running using Vagrant and Puppet.

## Getting started

Before you start, ensure you have [VirtualBox](https://www.virtualbox.org/wiki/Downloads) and [Vagrant](http://www.vagrantup.com/) installed and working.

1. `git clone --recursive https://github.com/ssejourne/shibboleth-vagrant.git && cd shibboleth-vagrant`
2. `vagrant up`

That's it! The VM will be created and Puppet will download and configure shibboleth for you.

You can check to make sure everything worked by visiting: https://shibboleth-idp.vagrant.dev/idp/status

Test it by starting to log in https://shibboleth-sp.vagrant.dev/secure

## Diagram

                  +-----+                 
                  |     |                 
                  | Host|                 
                  |     |                 
                  +--+--+  .20 for VIP
                     |.1        192.168.66.0/24          
    +-+------+-------+---+-----------+---+
      |      |.2         |.5         |.10 
      |   +--+--+     +--+--+     +--+--+ 
      |   |     |     |     |     |     | 
      |   MONITOR     HAPROXY     | SP  | 
      |   |     |     |     |     |LDAP | 
      |   +--+--+     +--+--+     +-----+ 
      |      |.2         |.5    192.168.65.0/24
    +-+------+----------++-----------+---+
                        |.21         |.22 
                     +--+--+      +--+--+ 
                     |     |      |     | 
                     | IdP1|      | IdP2| 
                     |     |      |     | 
                     +-----+      +-----+ 
        

## Servers

### IDP - shibboleth-idp.vagrant.dev

* URLs
  * https://shibboleth-idp.vagrant.dev/idp/status
  * https://shibboleth-idp.vagrant.dev/idp/profile/Metadata/SAML : Metadataprovider

### SP - shibboleth-sp.vagrant.dev

* URLs
  * https://shibboleth-sp.vagrant.dev/secure : Content we want to secure (apache defined)
  * https://shibboleth-sp.vagrant.dev/Shibboleth.sso/Login : Content we want to secure (shibd defined)
  * https://shibboleth-sp.vagrant.dev/Shibboleth.sso/Metadata : SP Metadata generator
  * https://shibboleth-sp.vagrant.dev/Shibboleth.sso/Status : Display SP status
  * https://shibboleth-sp.vagrant.dev/Shibboleth.sso/Session : Display SP sessions
  * https://shibboleth-sp.vagrant.dev/Shibboleth.sso/DiscoveryFeed : ...

### LDAP
On shibboleth-sp.vagrant.dev

* URL (LDAP Account Manager) : https://shibboleth-idp.vagrant.dev/lam
  * LDAP Account Manager admin user : lam / lam
* LDAP Manager : admin / vagrant
* Logins password are login with '123' at the end

### HAPROXY

* URLs
  * http://ha-proxy.vagrant.dev/haproxy?stats

### MONITOR

* Graphite + collectd + jmxtrans
* URLs
  * http://monitor.vagrant.dev/dashboard/ : Dashboards
  * http://monitor.vagrant.dev/render?target=collectd.ha-proxy_vagrant_dev.interface-eth1.*.*&format=csv : Export some data in CSV (or &format=json for JSON)

### REFERENCES
* https://github.com/puppetlabs/puppetlabs-apache
* https://github.com/puppetlabs/puppetlabs-apt
* https://github.com/pdxcat/puppet-module-collectd
* https://github.com/puppetlabs/puppetlabs-concat
* https://github.com/echocat/puppet-graphite
* https://github.com/datacentred/datacentred-ldap
* https://github.com/puppetlabs/puppetlabs-nodejs
* https://github.com/hercules-team/augeasproviders_core
* https://github.com/hercules-team/augeasproviders_shellvar
* https://github.com/Aethylred/puppet-shibboleth
* https://github.com/justindowning/puppet-statsd
* https://github.com/puppetlabs/puppetlabs-stdlib

