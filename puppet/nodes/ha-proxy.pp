################
### HA-PROXY ###
################

# Configure the node now
node 'ha-proxy.vagrant.dev' {
  Exec {
    path => '/usr/local/bin:/usr/bin:/usr/sbin:/bin'
  }

  include baseconfig


}

