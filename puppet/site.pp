
Exec {
  path => '/usr/local/bin:/usr/bin:/usr/sbin:/bin'
}

# set defaults for file ownership/permissions
File {
  owner => 'root',
  group => 'root',
  mode => '0644',
}

include baseconfig

import 'nodes/**/*.pp'

