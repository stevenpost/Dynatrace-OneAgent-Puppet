# frozen_string_literal: true

require 'spec_helper'

describe 'dynatraceoneagent' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      let(:params) do
        {
          'tenant_url' => 'https://live.dynatrace.com',
          'paas_token' => 'my_paas_token',
        }
      end

      it { is_expected.to compile.with_all_deps }
      it {
        is_expected.to contain_exec('install_oneagent')
          .with(
            command: '/bin/sh /tmp/Dynatrace-OneAgent-Linux-latest.sh --set-infra-only=false --set-app-log-content-access=true',
            cwd: '/tmp',
            timeout: 6000,
            creates: '/var/lib/dynatrace/oneagent/agent/config/agent.state',
            logoutput: 'on_failure',
          )
      }
      it { is_expected.not_to contain_reboot('after') }
      it {
        is_expected.to contain_file('/var/lib/dynatrace/oneagent/agent/config/puppet')
          .with(
            ensure: 'directory',
            owner: 'root',
            group: 'root',
            mode: '0644',
          )
      }
      it {
        is_expected.to contain_file('/var/lib/dynatrace/oneagent/agent/config/puppet/infraonly.conf')
          .with(
            ensure: 'absent',
          )
      }
      it {
        is_expected.to contain_exec('set_monitoring_mode')
          .with(
            command: 'oneagentctl --set-monitoring-mode=fullstack --restart-service',
            path: ['/usr/bin/', '/opt/dynatrace/oneagent/agent/tools'],
            cwd: '/opt/dynatrace/oneagent/agent/tools',
            timeout: 6000,
            logoutput: 'on_failure',
            unless: 'oneagentctl --get-monitoring-mode | grep -q fullstack',
          )
      }

      context 'with "reboot_system => true"' do
        let(:params) do
          super().merge('reboot_system' => true)
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_exec('install_oneagent').that_notifies('Reboot[after]') }
        it { is_expected.to contain_reboot('after') }
      end

      context 'with "monitoring_mode => discovery"' do
        let(:params) do
          super().merge('monitoring_mode' => 'discovery')
        end

        it { is_expected.to compile.with_all_deps }
        it {
          is_expected.to contain_exec('set_monitoring_mode')
            .with(
              command: 'oneagentctl --set-monitoring-mode=discovery --restart-service',
              unless: 'oneagentctl --get-monitoring-mode | grep -q discovery',
            )
        }
      end

      context 'with "monitoring_mode => infra-only"' do
        let(:params) do
          super().merge('monitoring_mode' => 'infra-only')
        end

        it { is_expected.to compile.with_all_deps }
        it {
          is_expected.to contain_exec('set_monitoring_mode')
            .with(
              command: 'oneagentctl --set-monitoring-mode=infra-only --restart-service',
              unless: 'oneagentctl --get-monitoring-mode | grep -q infra-only',
            )
        }
      end

      context 'when uninstalling' do
        let(:params) do
          super().merge('package_state' => 'absent')
        end

        it { is_expected.to compile.with_all_deps }
        it {
          is_expected.to contain_exec('uninstall_oneagent')
            .with(
              command: '/opt/dynatrace/oneagent/agent/uninstall.sh',
              onlyif: '/usr/bin/test -f /var/lib/dynatrace/oneagent/agent/config/agent.state',
              timeout: 6000,
            )
        }
        it { is_expected.not_to contain_exec('install_oneagent') }
      end
    end
  end
end
