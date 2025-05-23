# @summary
#   This class manages the installation of the OneAgent on the host
#
class dynatraceoneagent::install {
  $state_file               = $dynatraceoneagent::state_file
  $download_dir             = $dynatraceoneagent::download_dir
  $download_path            = $dynatraceoneagent::download_path
  $reboot_system            = $dynatraceoneagent::reboot_system
  $oneagent_params_hash     = $dynatraceoneagent::oneagent_params_hash
  $oneagent_params_array    = $oneagent_params_hash.map |$key,$value| { "${key}=${value}" }

  $install_command_array = ['/bin/sh', $download_path] + $oneagent_params_array

  exec { 'install_oneagent':
    command   => $install_command_array,
    cwd       => $download_dir,
    timeout   => 6000,
    creates   => $state_file,
    logoutput => on_failure,
  }

  if ($reboot_system) {
    reboot { 'after':
      subscribe => Exec['install_oneagent'],
    }
  }
}
