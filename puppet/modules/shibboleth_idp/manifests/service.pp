# Actions:
#   - Manage shibboleth identity provider service
#
# Requires:
#
# Sample Usage:
#
#    sometype { 'foo':
#      notify => Class['shibboleth_idp::service'],
#    }
#
#
#class shibboleth_idp::service inherits $::tomcat::service (
#  $service_name = $shibboleth_idp::params::service_name,
#) {
#}
