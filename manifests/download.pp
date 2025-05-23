# @api private
#
# @summary
#   This class downloads the OneAgent installer binary
#
class dynatraceoneagent::download {
  if !defined('archive') {
    class { 'archive':
      seven_zip_provider => '',
    }
  }

  $state_file           = $dynatraceoneagent::state_file
  $download_dir         = $dynatraceoneagent::download_dir
  $filename             = $dynatraceoneagent::filename
  $download_path        = $dynatraceoneagent::download_path
  $proxy_server         = $dynatraceoneagent::proxy_server
  $allow_insecure       = $dynatraceoneagent::allow_insecure
  $download_options     = $dynatraceoneagent::download_options
  $download_link        = $dynatraceoneagent::download_link
  $download_cert_link   = $dynatraceoneagent::download_cert_link
  $cert_file_name       = $dynatraceoneagent::cert_file_name
  $ca_cert_src_path     = $dynatraceoneagent::ca_cert_src_path
  $package_state        = $dynatraceoneagent::package_state
  $global_mode          = $dynatraceoneagent::global_mode

  if $download_dir != '/tmp' {
    file { $download_dir:
      ensure => directory,
      before => Archive[$filename],
    }
  }

  archive { $filename:
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
    file { $dynatraceoneagent::dt_root_cert:
      ensure => file,
      mode   => $global_mode,
      source => "puppet:///${ca_cert_src_path}",
    }

    $verify_signature_command = "( echo 'Content-Type: multipart/signed; protocol=\"application/x-pkcs7-signature\"; micalg=\"sha-256\";\
     boundary=\"--SIGNED-INSTALLER\"'; echo ; echo ; echo '----SIGNED-INSTALLER' ; \
     cat ${download_path} ) | openssl cms -verify -CAfile ${dynatraceoneagent::dt_root_cert} > /dev/null"

    exec { 'delete_oneagent_installer_script':
      command   => "rm ${$download_path} ${dynatraceoneagent::dt_root_cert}",
      path      => ['/usr/bin'],
      cwd       => $download_dir,
      timeout   => 6000,
      logoutput => on_failure,
      unless    => $verify_signature_command,
      require   => [
        File[$dynatraceoneagent::dt_root_cert],
        Archive[$filename],
      ],
      creates   => $state_file,
    }
  }
}
