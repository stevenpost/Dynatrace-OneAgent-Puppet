# @summary
#   This class manages the configuration of the OneAgent
#
class dynatraceoneagent::config {
  $global_owner                        = $dynatraceoneagent::global_owner
  $global_group                        = $dynatraceoneagent::global_group
  $global_mode                         = $dynatraceoneagent::global_mode
  $install_dir                         = $dynatraceoneagent::install_dir
  $state_file                          = $dynatraceoneagent::state_file
  $package_state                       = $dynatraceoneagent::package_state
  $service_state                       = $dynatraceoneagent::service_state

  # OneAgent Host Configuration Parameters
  $oneagent_tools_dir                  = $dynatraceoneagent::oneagent_tools_dir
  $oactl                               = 'oneagentctl'
  $oneagent_communication_hash         = $dynatraceoneagent::oneagent_communication_hash
  $log_monitoring                      = $dynatraceoneagent::log_monitoring
  $log_access                          = $dynatraceoneagent::log_access
  $host_group                          = $dynatraceoneagent::host_group
  $host_tags                           = $dynatraceoneagent::host_tags
  $host_metadata                       = $dynatraceoneagent::host_metadata
  $hostname                            = $dynatraceoneagent::hostname
  $monitoring_mode                     = $dynatraceoneagent::monitoring_mode
  $network_zone                        = $dynatraceoneagent::network_zone
  $oneagent_puppet_conf_dir            = $dynatraceoneagent::oneagent_puppet_conf_dir

  $oneagent_comms_config_file          = "${oneagent_puppet_conf_dir}/deployment.conf"
  $oneagent_logmonitoring_config_file  = "${oneagent_puppet_conf_dir}/logmonitoring.conf"
  $oneagent_logaccess_config_file      = "${oneagent_puppet_conf_dir}/logaccess.conf"
  $hostgroup_config_file               = "${oneagent_puppet_conf_dir}/hostgroup.conf"
  $hostautotag_config_file             = "${oneagent_puppet_conf_dir}/hostautotag.conf"
  $hostmetadata_config_file            = "${oneagent_puppet_conf_dir}/hostcustomproperties.conf"
  $hostname_config_file                = "${oneagent_puppet_conf_dir}/hostname.conf"
  $oneagent_infraonly_config_file      = "${oneagent_puppet_conf_dir}/infraonly.conf"
  $oneagent_networkzone_config_file    = "${oneagent_puppet_conf_dir}/networkzone.conf"

  file { $oneagent_puppet_conf_dir :
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

  $oneagent_set_host_tags_array        = $host_tags.map |$value| { "--set-host-tag=${value}" }
  $oneagent_set_host_tags_params       = join($oneagent_set_host_tags_array, ' ' )
  $oneagent_set_host_metadata_array    = $host_metadata.map |$value| { "--set-host-property=${value}" }
  $oneagent_set_host_metadata_params   = join($oneagent_set_host_metadata_array, ' ' )
  $oneagent_communication_array        = $oneagent_communication_hash.map |$key,$value| { "${key}=${value}" }
  $oneagent_communication_params       = join($oneagent_communication_array, ' ' )

  $oneagentctl_exec_path                 = ['/usr/bin/', $oneagent_tools_dir]
  $oneagent_remove_host_tags_command     = "${oactl} --get-host-tags | xargs -I{} ${oactl} --remove-host-tag={}"
  $oneagent_set_host_tags_command        = "${oneagent_remove_host_tags_command}; ${oactl} ${oneagent_set_host_tags_params}"
  $oneagent_remove_host_metadata_command = "${oactl} --get-host-properties | xargs -I{} ${oactl} --remove-host-property={}"
  $oneagent_set_host_metadata_command    = "${oneagent_remove_host_metadata_command}; ${oactl} ${oneagent_set_host_metadata_params}"

  if $oneagent_communication_array.length > 0 {
    file { $oneagent_comms_config_file:
      ensure  => file,
      content => String($oneagent_communication_hash),
      notify  => Exec['set_oneagent_communication'],
      mode    => $global_mode,
    }
  } else {
    file { $oneagent_comms_config_file:
      ensure => absent,
    }
  }

  file { $oneagent_logmonitoring_config_file:
    ensure => absent,
  }

  file { $oneagent_logaccess_config_file:
    ensure => absent,
  }

  file { $hostgroup_config_file:
    ensure => absent,
  }

  if $host_tags.length > 0 {
    file { $hostautotag_config_file:
      ensure  => file,
      content => String($host_tags),
      notify  => Exec['set_host_tags'],
      mode    => $global_mode,
    }
  } else {
    file { $hostautotag_config_file:
      ensure => absent,
      notify => Exec['unset_host_tags'],
    }
  }

  if $host_metadata.length > 0 {
    file { $hostmetadata_config_file:
      ensure  => file,
      content => String($host_metadata),
      notify  => Exec['set_host_metadata'],
      mode    => $global_mode,
    }
  } else {
    file { $hostmetadata_config_file:
      ensure => absent,
      notify => Exec['unset_host_metadata'],
    }
  }

  if $hostname {
    file { $hostname_config_file:
      ensure  => file,
      content => $hostname,
      notify  => Exec['set_hostname'],
      mode    => $global_mode,
    }
  } else {
    file { $hostname_config_file:
      ensure => absent,
      notify => Exec['unset_hostname'],
    }
  }

  file { $oneagent_infraonly_config_file:
    ensure => absent,
  }

  file { $oneagent_networkzone_config_file:
    ensure => absent,
  }

  exec { 'set_oneagent_communication':
    command     => "${oactl} ${oneagent_communication_params} --restart-service",
    path        => $oneagentctl_exec_path,
    cwd         => $oneagent_tools_dir,
    timeout     => 6000,
    logoutput   => on_failure,
    refreshonly => true,
  }

  exec { 'set_log_monitoring':
    command   => "${oactl} --set-app-log-content-access=${log_monitoring} --restart-service",
    path      => $oneagentctl_exec_path,
    cwd       => $oneagent_tools_dir,
    timeout   => 6000,
    logoutput => on_failure,
    unless    => "${oactl} --get-app-log-content-access | grep -q ${log_monitoring}",
  }

  exec { 'set_log_access':
    command   => "${oactl} --set-system-logs-access-enabled=${log_access} --restart-service",
    path      => $oneagentctl_exec_path,
    cwd       => $oneagent_tools_dir,
    timeout   => 6000,
    logoutput => on_failure,
    unless    => "${oactl} --get-system-logs-access-enabled | grep -q ${log_access}",
  }

  if $host_group == undef {
    $_host_group_onlyif = "[ \$(${oactl} --get-host-group) ]"
    $_host_group_unless = undef
  }
  else {
    $_host_group_onlyif = undef
    $_host_group_unless = "${oactl} --get-host-group | grep -q '^${host_group}$'"
  }

  exec { 'set_host_group':
    command   => "${oactl} --set-host-group=${host_group} --restart-service",
    path      => $oneagentctl_exec_path,
    cwd       => $oneagent_tools_dir,
    timeout   => 6000,
    logoutput => on_failure,
    onlyif    => $_host_group_onlyif,
    unless    => $_host_group_unless,
  }

  exec { 'set_host_tags':
    command     => $oneagent_set_host_tags_command,
    path        => $oneagentctl_exec_path,
    cwd         => $oneagent_tools_dir,
    timeout     => 6000,
    logoutput   => on_failure,
    refreshonly => true,
  }

  exec { 'unset_host_tags':
    command     => $oneagent_remove_host_tags_command,
    path        => $oneagentctl_exec_path,
    cwd         => $oneagent_tools_dir,
    timeout     => 6000,
    logoutput   => on_failure,
    refreshonly => true,
  }

  exec { 'set_host_metadata':
    command     => $oneagent_set_host_metadata_command,
    path        => $oneagentctl_exec_path,
    cwd         => $oneagent_tools_dir,
    timeout     => 6000,
    logoutput   => on_failure,
    refreshonly => true,
  }

  exec { 'unset_host_metadata':
    command     => $oneagent_remove_host_metadata_command,
    path        => $oneagentctl_exec_path,
    cwd         => $oneagent_tools_dir,
    timeout     => 6000,
    logoutput   => on_failure,
    refreshonly => true,
  }

  exec { 'set_hostname':
    command     => "${oactl} --set-host-name=${hostname} --restart-service",
    path        => $oneagentctl_exec_path,
    cwd         => $oneagent_tools_dir,
    timeout     => 6000,
    logoutput   => on_failure,
    refreshonly => true,
  }

  exec { 'unset_hostname':
    command     => "${oactl} --set-host-name=\"\" --restart-service",
    path        => $oneagentctl_exec_path,
    cwd         => $oneagent_tools_dir,
    timeout     => 6000,
    logoutput   => on_failure,
    refreshonly => true,
  }

  exec { 'set_monitoring_mode':
    command   => "${oactl} --set-monitoring-mode=${monitoring_mode} --restart-service",
    path      => $oneagentctl_exec_path,
    cwd       => $oneagent_tools_dir,
    timeout   => 6000,
    logoutput => on_failure,
    unless    => "${oactl} --get-monitoring-mode | grep -q ${monitoring_mode}",
  }

  if $network_zone == undef {
    $_network_zone_onlyif = "[ \$(${oactl} --get-network-zone) ]"
    $_network_zone_unless = undef
  }
  else {
    $_network_zone_onlyif = undef
    $_network_zone_unless = "${oactl} --get-network-zone | grep -q '^${network_zone}$'"
  }

  exec { 'set_network_zone':
    command   => "${oactl} --set-network-zone=${network_zone} --restart-service",
    path      => $oneagentctl_exec_path,
    cwd       => $oneagent_tools_dir,
    timeout   => 6000,
    logoutput => on_failure,
    onlyif    => $_network_zone_onlyif,
    unless    => $_network_zone_unless,
  }
}
