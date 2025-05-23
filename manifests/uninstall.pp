# @api private
#
# @summary
#   Uninstalls the Dynatrace OneAgent
#
class dynatraceoneagent::uninstall {
  $install_dir = $dynatraceoneagent::install_dir
  $state_file  = $dynatraceoneagent::state_file

  exec { 'uninstall_oneagent':
    command   => "${install_dir}/agent/uninstall.sh",
    timeout   => 6000,
    logoutput => on_failure,
    onlyif    => "/usr/bin/test -f ${state_file}",
  }
}
