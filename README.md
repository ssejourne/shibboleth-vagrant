# Shibboleth Vagrant

Get an instance of [Shibboleth](https://shibboleth.net/products/identity-provider.html) SP and Idp up and running using Vagrant and Puppet.

## Getting started

Before you start, ensure you have [VirtualBox](https://www.virtualbox.org/wiki/Downloads) and [Vagrant](http://www.vagrantup.com/) installed and working.

1. `git clone https://github.com/ssejourne/shibboleth-vagrant.git && cd shibboleth-vagrant`
2. `vagrant up`

That's it! The VM will be created and Puppet will download and configure shibboleth for you.

You can check to make sure everything worked by visiting: https://shibboleth-idp.vagrant.dev/idp/status
