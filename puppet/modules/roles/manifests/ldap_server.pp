# Define an LDAP server
class roles::ldap_server inherits roles {

  include ::profiles::ldap::server
}

