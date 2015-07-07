# Define an LB role which include haproxy profile
# and LDAP server
class roles::lb inherits roles {

  include ::profiles::haproxy

  # Act as LDAP server as well
  include ::profiles::ldap::server
}

