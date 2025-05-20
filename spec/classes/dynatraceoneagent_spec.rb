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

      context 'with "infra_only => true' do
        let(:params) do
          super().merge('infra_only' => true)
        end

        it { is_expected.to compile.with_all_deps }
        it {
          is_expected.to contain_file('/var/lib/dynatrace/oneagent/agent/config/puppet/infraonly.conf')
            .with(
              ensure: 'file',
              mode: '0644',
              content: 'true',
            )
        }
        it {
          is_expected.to contain_file('/var/lib/dynatrace/oneagent/agent/config/puppet/infraonly.conf')
            .that_notifies('Exec[set_infra_only]')
        }
        it {
          is_expected.to contain_exec('set_infra_only')
            .with(
              command: 'oneagentctl --set-infra-only=true --restart-service',
              path: ['/usr/bin/', '/opt/dynatrace/oneagent/agent/tools'],
              timeout: 6000,
              logoutput: 'on_failure',
              refreshonly: true,
            )
        }
      end
      context 'with "infra_only => false' do
        let(:params) do
          super().merge('infra_only' => false)
        end

        it { is_expected.to compile.with_all_deps }
        it {
          is_expected.to contain_file('/var/lib/dynatrace/oneagent/agent/config/puppet/infraonly.conf')
            .with(
              ensure: 'file',
              mode: '0644',
              content: 'false',
            )
        }
        it {
          is_expected.to contain_file('/var/lib/dynatrace/oneagent/agent/config/puppet/infraonly.conf')
            .that_notifies('Exec[set_infra_only]')
        }
        it {
          is_expected.to contain_exec('set_infra_only')
            .with(
              command: 'oneagentctl --set-infra-only=false --restart-service',
              path: ['/usr/bin/', '/opt/dynatrace/oneagent/agent/tools'],
              timeout: 6000,
              logoutput: 'on_failure',
              refreshonly: true,
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
              onlyif: '/usr/bin/test -f /var/lib/dynatrace/oneagent/agent/agent.state',
              timeout: 6000,
            )
        }
      end
    end
  end
end
