# Shibboleth Vagrant

Get an instance of [Shibboleth](https://shibboleth.net/products/identity-provider.html) SP and Idp up and running using Vagrant and Puppet.

## Getting started

Before you start, ensure you have [VirtualBox](https://www.virtualbox.org/wiki/Downloads) and [Vagrant](http://www.vagrantup.com/) installed and working.

1. `git clone https://github.com/ssejourne/shibboleth-vagrant.git && cd shibboleth-vagrant`
2. `vagrant up`

That's it! The VM will be created and Puppet will download and configure shibboleth for you.

You can check to make sure everything worked by visiting: https://shibboleth-idp.vagrant.dev/idp/status

Test it by starting to log in https://shibboleth-sp.vagrant.dev/Shibboleth.sso/Login

## Diagram

          +-----+                 
          |     |                 
          | Host|                 
          |     |                 
          +--+--+ 192.168.66.0/24 
             |.1                  
 +---+-------+---+-----------+---+
     |.5         |.20        |.10 
  +--+--+     +--+--+     +--+--+ 
  |     |     |     |     |     | 
  |LDAP |     | IdP |     | SP  | 
  |     |     |     |     |     | 
  +-----+     +-----+     +-----+ 
                                 

## Servers

### IDP - shibboleth-idp.vagrant.dev

* URLs
  * https://shibboleth-idp.vagrant.dev/idp/status
  * https://shibboleth-idp.vagrant.dev/idp/profile/Metadata/SAML : Metadataprovider

### SP - shibboleth-sp.vagrant.dev

* URLs
  * https://shibboleth-sp.vagrant.dev/Shibboleth.sso/Login : Content we want to secure
  * https://shibboleth-sp.vagrant.dev/Shibboleth.sso/Metadata : SP Metadata generator
  * https://shibboleth-sp.vagrant.dev/Shibboleth.sso/Status : Display SP status
  * https://shibboleth-sp.vagrant.dev/Shibboleth.sso/Session : Display SP sessions
  * https://shibboleth-sp.vagrant.dev/Shibboleth.sso/DiscoveryFeed : ...

### LDAP
On shibboleth-idp.vagrant.dev

* URL (LDAP Account Manager) : https://shibboleth-idp.vagrant.dev/lam
  * LDAP Account Manager admin user : lam / lam
* LDAP Manager : admin / vagrant
* Logins password are login with '123' at the end

### HAPROXY

TODO
