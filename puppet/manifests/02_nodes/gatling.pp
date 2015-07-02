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

  include gatling
}

