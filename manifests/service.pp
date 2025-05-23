# @api private
#
# @summary
#   Manages the OneAgent service
#
class dynatraceoneagent::service {
  $service_state  = $dynatraceoneagent::service_state
  $manage_service = $dynatraceoneagent::manage_service

  if $manage_service {
    $service_enable = $service_state ? {
      'running' => true,
      default   => false,
    }

    service { 'oneagent':
      ensure     => $service_state,
      enable     => $service_enable,
      hasstatus  => true,
      hasrestart => true,
    }
  }
}
