class roles {
  include ::profiles::baseconfig

  info("${::hostname} is ${::operatingsystem} with role ${::role}")
}
