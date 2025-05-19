# @summary
#   Uninstalls the Dynatrace OneAgent
#
class dynatraceoneagent::uninstall {
  $provider    = $dynatraceoneagent::provider
  $install_dir = $dynatraceoneagent::install_dir
  $created_dir = $dynatraceoneagent::created_dir

  exec { 'uninstall_oneagent':
    command   => "${install_dir}/agent/uninstall.sh",
    timeout   => 6000,
    provider  => $provider,
    logoutput => on_failure,
    onlyif    => "/usr/bin/test -f ${created_dir}",
  }
}
