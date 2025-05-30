# @api private
#
# @summary
#   This class manages the installation of the OneAgent on the host
#
class dynatraceoneagent::install {
  if !defined('archive') {
    class { 'archive':
      seven_zip_provider => '',
    }
  }

  $allow_insecure            = $dynatraceoneagent::allow_insecure
  $download_dir              = $dynatraceoneagent::download_dir
  $download_link             = $dynatraceoneagent::download_link
  $download_options          = $dynatraceoneagent::download_options
  $download_path             = $dynatraceoneagent::download_path
  $filename                  = $dynatraceoneagent::filename
  $global_mode               = $dynatraceoneagent::global_mode
  $package_state             = $dynatraceoneagent::package_state
  $proxy_server              = $dynatraceoneagent::proxy_server
  $reboot_system             = $dynatraceoneagent::reboot_system
  $state_file                = $dynatraceoneagent::state_file
  $real_oneagent_params_hash = $dynatraceoneagent::real_oneagent_params_hash
  $oneagent_params_array     = $real_oneagent_params_hash.map |$key,$value| { "${key}=${value}" }

  $cert_file_name            = 'dt-root.cert.pem'
  $dt_root_cert              = "${download_dir}/${cert_file_name}"

  if $download_dir != '/tmp' {
    file { $download_dir:
      ensure => directory,
      before => Archive['oneagent_installer'],
    }
  }

  archive { 'oneagent_installer':
    ensure           => present,
    extract          => false,
    source           => $download_link,
    path             => $download_path,
    allow_insecure   => $allow_insecure,
    creates          => $state_file,
    proxy_server     => $proxy_server,
    cleanup          => false,
    download_options => $download_options,
  }

  if  $dynatraceoneagent::verify_signature {
    file { $dt_root_cert:
      ensure => file,
      mode   => $global_mode,
      source => "puppet:///modules/${module_name}/${cert_file_name}",
    }

    $verify_signature_command = @("HERE"/L)
    ( echo 'Content-Type: multipart/signed; protocol="application/x-pkcs7-signature"; micalg="sha-256";\
    boundary="--SIGNED-INSTALLER"'; echo ; echo ; echo '----SIGNED-INSTALLER' ; \
    cat ${download_path} ) | openssl cms -verify -CAfile ${dt_root_cert} > /dev/null\
    |HERE

    exec { 'verify_oneagent_installer':
      command => ['bash', '-c', $verify_signature_command],
      path    => ['/usr/bin'],
      unless  => "/usr/bin/test -f ${state_file}",
      require => [
        File[$dt_root_cert],
        Archive['oneagent_installer'],
      ],
      before  => Exec['install_oneagent'],
    }
  }

  $install_command_array = ['/bin/sh', $download_path] + $oneagent_params_array

  exec { 'install_oneagent':
    command   => $install_command_array,
    cwd       => $download_dir,
    timeout   => 6000,
    creates   => $state_file,
    logoutput => on_failure,
    require   => Archive['oneagent_installer'],
  }

  exec { 'delete_oneagent_installer_script':
    command => "rm ${$download_path}",
    path    => ['/usr/bin'],
    onlyif  => "/usr/bin/test -f ${download_path}",
    require => Exec['install_oneagent'],
  }

  if ($reboot_system) {
    reboot { 'after':
      subscribe => Exec['install_oneagent'],
    }
  }
}
