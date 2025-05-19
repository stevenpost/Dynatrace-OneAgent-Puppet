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
    end
  end
end
