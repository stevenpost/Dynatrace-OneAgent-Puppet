# @summary
#   This module deploys the OneAgent on Linux Operating Systems with different available configurations and ensures
#   the OneAgent service maintains a running state.
#
# @example Basic usage
#    class { 'dynatraceoneagent':
#        tenant_url  => 'https://{your-environment-id}.live.dynatrace.com',
#        paas_token  => '{your-paas-token}',
#    }
#
# @param tenant_url
#   URL of your dynatrace Tenant
#   Managed `https://{your-domain}/e/{your-environment-id}` - SaaS `https://{your-environment-id}.live.dynatrace.com`
# @param paas_token
#   Paas token for downloading the OneAgent installer
# @param api_path
#   Path of the Dynatrace OneAgent deployment API
# @param version
#   The required version of the OneAgent in 1.155.275.20181112-084458 format
# @param arch
#   The architecture of your OS
# @param installer_type
#   The type of the installer
# @param verify_signature
#   Verify OneAgent installer signature (Linux only).
# @param proxy_server
#   Proxy server to be used by the archive module for downloading the OneAgent installer if needed
# @param allow_insecure
#   Ignore HTTPS certificate errors when using the archive module.
# @param download_options
#   In some cases you may need custom flags for curl/wget/s3 which can be supplied via download_options.
#   Refer to [Download Customizations](https://github.com/voxpupuli/puppet-archive#download-customizations)
# @param download_dir
#   OneAgent installer file download directory.
# @param oneagent_params_hash
#   Hash map of additional parameters to pass to the installer
#   Refer to the Customize OneAgent installation documentation on [Technology Support](https://www.dynatrace.com/support/help/technology-support/operating-systems/)
# @param reboot_system
#   If set to true, puppet will reboot the server after installing the OneAgent
# @param service_state
#   What state the dynatrace oneagent service should be in
# @param manage_service
#   Whether puppet should manage the state of the OneAgent service
# @param package_state
#   What state the dynatrace oneagent package should be in
# @param host_tags
#   Values to automatically add tags to a host,
#   should contain an array of strings or key/value pairs.
#   For example: ['Environment=Prod', 'Organization=D1P', 'Owner=john.doe@dynatrace.com', 'Support=https://www.dynatrace.com/support/linux']
# @param host_metadata
#   Values to automatically add metadata to a host,
#   Should contain an array of strings or key/value pairs.
#   For example: ['LinuxHost', 'Gdansk', 'role=fallback', 'app=easyTravel']
# @param hostname
#   Overrides an automatically detected host name. Example: My App Server
# @param oneagent_communication_hash
#   Hash map of parameters used to change OneAgent communication settings
#   Refer to Change OneAgent communication settings on [Communication Settings](https://www.dynatrace.com/support/help/shortlink/oneagentctl#change-oneagent-communication-settings)
# @param log_monitoring
#   Enable or disable Log Monitoring
# @param log_access
#   Enable or disable access to system logs
# @param host_group
#   Change host group assignment
# @param monitoring_mode
#   Set the monitoring mode
# @param network_zone
#   Set the network zone for the host
# @param oneagent_puppet_conf_dir
#   Directory puppet will use to store oneagent configurations
#
class dynatraceoneagent (
  String $tenant_url,
  String $paas_token,

  # OneAgent Download Parameters
  String $api_path                                            = '/api/v1/deployment/installer/agent/',
  String $version                                             = 'latest',
  String $arch                                                = 'all',
  String $installer_type                                      = 'default',
  Boolean $verify_signature                                   = true,
  Optional[String] $proxy_server                              = undef,
  Boolean $allow_insecure                                     = false,
  Optional $download_options                                  = undef,

  # OneAgent Install Parameters
  String $download_dir                                        = '/tmp',
  Boolean $reboot_system                                      = false,
  Enum['running','stopped'] $service_state                    = 'running',
  Boolean $manage_service                                     = true,
  Enum['present','absent'] $package_state                     = 'present',

  # OneAgent Host Configuration Parameters
  Hash $oneagent_communication_hash                           = {},
  Boolean $log_monitoring                                     = true,
  Boolean $log_access                                         = true,
  Optional[String[1]] $host_group                             = undef,
  Array $host_tags                                            = [],
  Array $host_metadata                                        = [],
  Optional[String[1]] $hostname                               = undef,
  Enum['fullstack','infra-only','discovery'] $monitoring_mode = 'fullstack',
  Hash $oneagent_params_hash                                  = {},
  Optional[String[1]] $network_zone                           = undef,
  String $oneagent_puppet_conf_dir                            = '/var/lib/dynatrace/oneagent/agent/config/puppet',

) {
  $global_mode = '0644'
  $default_install_dir = '/opt/dynatrace/oneagent'
  $global_owner = 'root'
  $global_group = 'root'

  if $facts['kernel'] == 'Linux' {
    $os_type = 'unix'
  } elsif $facts['os']['family']  == 'AIX' {
    $os_type = 'aix'
  }

  if $oneagent_params_hash['INSTALL_PATH'] {
    $install_dir = $oneagent_params_hash['INSTALL_PATH']
  } else {
    $install_dir = $default_install_dir
  }

  $host_group_param = $host_group ? {
    undef   => {},
    default => { '--set-host-group' => $host_group },
  }
  $hostname_param = $hostname ? {
    undef   => {},
    default => { '--set-host-name' => $hostname },
  }
  $network_zone_param = $network_zone ? {
    undef   => {},
    default => { '--set-network-zone' => $network_zone },
  }
  $log_access_param = $log_access ? {
    false   => { '--set-system-logs-access-enabled' => 'false' },
    default => {},
  }
  $monitoring_mode_param = { '--set-monitoring-mode'       => $monitoring_mode }
  $log_monitoring_param = { '--set-app-log-content-access' => $log_monitoring }

  $real_oneagent_params_hash = $oneagent_params_hash
  + $monitoring_mode_param
  + $log_monitoring_param
  + $host_group_param
  + $hostname_param
  + $network_zone_param
  + $log_access_param

  if $version == 'latest' {
    $download_link  = "${tenant_url}${api_path}${os_type}/${installer_type}/latest/?Api-Token=${paas_token}&arch=${arch}"
  } else {
    $download_link  = "${tenant_url}${api_path}${os_type}/${installer_type}/version/${version}?Api-Token=${paas_token}&arch=${arch}"
  }

  $filename           = "Dynatrace-OneAgent-${facts['kernel']}-${version}.sh"
  $download_path      = "${download_dir}/${filename}"
  $state_file         = '/var/lib/dynatrace/oneagent/agent/config/agent.state'
  $oneagent_tools_dir = "${$install_dir}/agent/tools"

  if $package_state != 'absent' {
    contain dynatraceoneagent::install
    contain dynatraceoneagent::config
    contain dynatraceoneagent::service

    Class['dynatraceoneagent::install']
    -> Class['dynatraceoneagent::config']
    -> Class['dynatraceoneagent::service']
  } else {
    contain dynatraceoneagent::uninstall
  }
}
