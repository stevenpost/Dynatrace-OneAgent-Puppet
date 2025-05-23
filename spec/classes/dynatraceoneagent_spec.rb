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
      it { is_expected.not_to contain_file('/tmp') }
      it {
        is_expected.to contain_exec('install_oneagent')
          .with(
            command: [
              '/bin/sh',
              '/tmp/Dynatrace-OneAgent-Linux-latest.sh',
              '--set-monitoring-mode=fullstack',
              '--set-app-log-content-access=true',
            ],
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
        is_expected.to contain_file('/var/lib/dynatrace/oneagent/agent/config/puppet/hostgroup.conf')
          .with(
            ensure: 'absent',
          )
      }
      it {
        is_expected.to contain_file('/var/lib/dynatrace/oneagent/agent/config/puppet/hostname.conf')
          .with(
            ensure: 'absent',
          )
      }
      it {
        is_expected.to contain_file('/var/lib/dynatrace/oneagent/agent/config/puppet/networkzone.conf')
          .with(
            ensure: 'absent',
          )
      }
      it {
        is_expected.to contain_file('/var/lib/dynatrace/oneagent/agent/config/puppet/logaccess.conf')
          .with(
            ensure: 'absent',
          )
      }
      it {
        is_expected.to contain_file('/var/lib/dynatrace/oneagent/agent/config/puppet/logmonitoring.conf')
          .with(
            ensure: 'absent',
          )
      }
      it {
        is_expected.to contain_file('/var/lib/dynatrace/oneagent/agent/config/puppet/infraonly.conf')
          .with(
            ensure: 'absent',
          )
      }
      it {
        is_expected.to contain_exec('set_host_group')
          .with(
            command: 'oneagentctl --set-host-group= --restart-service',
            path: ['/usr/bin/', '/opt/dynatrace/oneagent/agent/tools'],
            cwd: '/opt/dynatrace/oneagent/agent/tools',
            timeout: 6000,
            logoutput: 'on_failure',
            onlyif: '[ $(oneagentctl --get-host-group) ]',
            unless: nil,
          )
      }
      it {
        is_expected.to contain_exec('set_hostname')
          .with(
            command: 'oneagentctl --set-host-name= --restart-service',
            path: ['/usr/bin/', '/opt/dynatrace/oneagent/agent/tools'],
            cwd: '/opt/dynatrace/oneagent/agent/tools',
            timeout: 6000,
            logoutput: 'on_failure',
            onlyif: '[ $(oneagentctl --get-host-name) ]',
            unless: nil,
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
      it {
        is_expected.to contain_exec('set_network_zone')
          .with(
            command: 'oneagentctl --set-network-zone= --restart-service',
            path: ['/usr/bin/', '/opt/dynatrace/oneagent/agent/tools'],
            cwd: '/opt/dynatrace/oneagent/agent/tools',
            timeout: 6000,
            logoutput: 'on_failure',
            onlyif: '[ $(oneagentctl --get-network-zone) ]',
            unless: nil,
          )
      }
      it {
        is_expected.to contain_exec('set_log_access')
          .with(
            command: 'oneagentctl --set-system-logs-access-enabled=true --restart-service',
            path: ['/usr/bin/', '/opt/dynatrace/oneagent/agent/tools'],
            cwd: '/opt/dynatrace/oneagent/agent/tools',
            timeout: 6000,
            logoutput: 'on_failure',
            unless: 'oneagentctl --get-system-logs-access-enabled | grep -q true',
          )
      }
      it {
        is_expected.to contain_exec('set_log_monitoring')
          .with(
            command: 'oneagentctl --set-app-log-content-access=true --restart-service',
            path: ['/usr/bin/', '/opt/dynatrace/oneagent/agent/tools'],
            cwd: '/opt/dynatrace/oneagent/agent/tools',
            timeout: 6000,
            logoutput: 'on_failure',
            unless: 'oneagentctl --get-app-log-content-access | grep -q true',
          )
      }
      it {
        is_expected.to contain_file('/var/lib/dynatrace/oneagent/agent/config/puppet/deployment.conf')
          .with(
            ensure: 'absent',
          )
      }
      it {
        is_expected.not_to contain_file('/var/lib/dynatrace/oneagent/agent/config/puppet/deployment.conf')
          .that_notifies('Exec[set_oneagent_communication]')
      }
      it {
        is_expected.to contain_exec('set_oneagent_communication')
          .with(
            refreshonly: true,
          )
      }

      context 'with "download_dir => /root/tmp"' do
        let(:params) do
          super().merge('download_dir' => '/root/tmp')
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file('/root/tmp').with(ensure: 'directory') }
        it {
          is_expected.to contain_archive('Dynatrace-OneAgent-Linux-latest.sh')
            .that_requires('File[/root/tmp]')
        }
      end

      context 'with "verify_signature => true"' do
        let(:params) do
          super().merge('verify_signature' => true)
        end

        it { is_expected.to compile.with_all_deps }
        it {
          is_expected.to contain_file('/tmp/dt-root.cert.pem')
            .with(
              ensure: 'file',
              mode: '0644',
              source: 'puppet:///modules/dynatraceoneagent/dt-root.cert.pem',
            )
        }
        it {
          is_expected.to contain_archive('Dynatrace-OneAgent-Linux-latest.sh')
        }
        it {
          is_expected.to contain_exec('delete_oneagent_installer_script')
            .with(
              command: 'rm /tmp/Dynatrace-OneAgent-Linux-latest.sh /tmp/dt-root.cert.pem',
              path: ['/usr/bin'],
            )
        }
        it { is_expected.to contain_exec('delete_oneagent_installer_script').that_requires('File[/tmp/dt-root.cert.pem]') }
        it { is_expected.to contain_exec('delete_oneagent_installer_script').that_requires('Archive[Dynatrace-OneAgent-Linux-latest.sh]') }
      end

      context 'with "reboot_system => true"' do
        let(:params) do
          super().merge('reboot_system' => true)
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_exec('install_oneagent').that_notifies('Reboot[after]') }
        it { is_expected.to contain_reboot('after') }
      end

      context 'with "host_group => testgroup"' do
        let(:params) do
          super().merge('host_group' => 'testgroup')
        end

        it { is_expected.to compile.with_all_deps }
        it {
          is_expected.to contain_exec('set_host_group')
            .with(
              command: 'oneagentctl --set-host-group=testgroup --restart-service',
              onlyif: nil,
              unless: 'oneagentctl --get-host-group | grep -q \'^testgroup$\'',
            )
        }
      end

      context 'with "hostname => testhost"' do
        let(:params) do
          super().merge('hostname' => 'testhost')
        end

        it { is_expected.to compile.with_all_deps }
        it {
          is_expected.to contain_exec('set_hostname')
            .with(
              command: 'oneagentctl --set-host-name=testhost --restart-service',
              onlyif: nil,
              unless: 'oneagentctl --get-host-name | grep -q \'^testhost$\'',
            )
        }
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
        it do
          install_command = catalogue.resource('Exec[install_oneagent]')[:command]
          expect(install_command).to include('--set-monitoring-mode=discovery')
        end
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
        it do
          install_command = catalogue.resource('Exec[install_oneagent]')[:command]
          expect(install_command).to include('--set-monitoring-mode=infra-only')
        end
      end

      context 'with "network_zone => testzone"' do
        let(:params) do
          super().merge('network_zone' => 'testzone')
        end

        it { is_expected.to compile.with_all_deps }
        it {
          is_expected.to contain_exec('set_network_zone')
            .with(
              command: 'oneagentctl --set-network-zone=testzone --restart-service',
              onlyif: nil,
              unless: 'oneagentctl --get-network-zone | grep -q \'^testzone$\'',
            )
        }
      end

      context 'with "log_access => false"' do
        let(:params) do
          super().merge('log_access' => false)
        end

        it { is_expected.to compile.with_all_deps }
        it {
          is_expected.to contain_exec('set_log_access')
            .with(
              command: 'oneagentctl --set-system-logs-access-enabled=false --restart-service',
              unless: 'oneagentctl --get-system-logs-access-enabled | grep -q false',
            )
        }
      end

      context 'with "log_monitoring => false"' do
        let(:params) do
          super().merge('log_monitoring' => false)
        end

        it { is_expected.to compile.with_all_deps }
        it {
          is_expected.to contain_exec('set_log_monitoring')
            .with(
              command: 'oneagentctl --set-app-log-content-access=false --restart-service',
              unless: 'oneagentctl --get-app-log-content-access | grep -q false',
            )
        }
        it do
          install_command = catalogue.resource('Exec[install_oneagent]')[:command]
          expect(install_command).to include('--set-app-log-content-access=false')
        end
      end

      context 'with "oneagent_communication_hash" => { "--set-server" => "https://example.com:9999", "--set-tenant" => "abcdefg" }' do
        let(:params) do
          super().merge(
            'oneagent_communication_hash' => {
              '--set-server': 'https://example.com:9999',
              '--set-tenant': 'abcdefg',
            },
          )
        end

        it {
          is_expected.to contain_file('/var/lib/dynatrace/oneagent/agent/config/puppet/deployment.conf')
            .with(
              ensure: 'file',
              owner: 'root',
              group: 'root',
              mode: '0640',
              content: sensitive(%r{'--set-server' => 'https://example.com:9999', '--set-tenant' => 'abcdefg'}),
            )
        }
        it {
          is_expected.to contain_file('/var/lib/dynatrace/oneagent/agent/config/puppet/deployment.conf')
            .that_notifies('Exec[set_oneagent_communication]')
        }
        it {
          is_expected.to contain_exec('set_oneagent_communication')
            .with(
              command: 'oneagentctl --set-server=https://example.com:9999 --set-tenant=abcdefg --restart-service',
              path: ['/usr/bin/', '/opt/dynatrace/oneagent/agent/tools'],
              cwd: '/opt/dynatrace/oneagent/agent/tools',
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
              onlyif: '/usr/bin/test -f /var/lib/dynatrace/oneagent/agent/config/agent.state',
              timeout: 6000,
            )
        }
        it { is_expected.not_to contain_exec('install_oneagent') }
      end
    end
  end
end
