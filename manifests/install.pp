# @summary
#   This class manages the installation of the OneAgent on the host
#
class dynatraceoneagent::install {
  $state_file               = $dynatraceoneagent::state_file
  $download_dir             = $dynatraceoneagent::download_dir
  $reboot_system            = $dynatraceoneagent::reboot_system

  exec { 'install_oneagent':
    command   => $dynatraceoneagent::command,
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
