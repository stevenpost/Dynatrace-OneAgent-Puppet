# @summary
#   Uninstalls the Dynatrace OneAgent
#
class dynatraceoneagent::uninstall {
  $provider    = $dynatraceoneagent::provider
  $install_dir = $dynatraceoneagent::install_dir
  $created_dir = $dynatraceoneagent::created_dir

  $created_dir_exists = find_file($created_dir)

  if $created_dir_exists {
    exec { 'uninstall_oneagent':
      command   => "${install_dir}/agent/uninstall.sh",
      timeout   => 6000,
      provider  => $provider,
      logoutput => on_failure,
    }
  }
}
