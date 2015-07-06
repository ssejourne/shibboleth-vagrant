###############
### GATLING ###
###############

# Configure the node now
node /^gatling.*$/ {
  Exec {
    path => '/usr/local/bin:/usr/bin:/usr/sbin:/bin'
  }

  hiera_include('classes')
  include baseconfig

  info("${::hostname} is ${::operatingsystem} with role ${::role}")

  include gatling
}

