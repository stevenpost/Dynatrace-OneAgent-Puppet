# @summary
#   Manages the OneAgent service
#
class dynatraceoneagent::service {
  $require_value  = $dynatraceoneagent::require_value
  $service_state  = $dynatraceoneagent::service_state
  $manage_service = $dynatraceoneagent::manage_service

  if $manage_service {
    service { 'oneagent':
      ensure     => $service_state,
      enable     => true,
      hasstatus  => true,
      hasrestart => true,
      require    => $require_value,
    }
  }
}
