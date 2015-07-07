################
### HA-PROXY ###
################

# Configure the node now
node /^ha-proxy.*$/ {

  include ::roles::lb
  include ::roles::ldap_server

}

