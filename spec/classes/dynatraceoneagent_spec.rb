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
