class shibboleth-sp {

  package { [ 'shibboleth-sp2-schemas', 'libapache2-mod-shib2' ]: ensure => installed }

  include shibboleth-sp::config
}
