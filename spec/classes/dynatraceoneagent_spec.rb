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
        is_expected.to contain_archive('oneagent_installer')
          .with(
            ensure: 'present',
            extract: false,
            source: 'https://live.dynatrace.com/api/v1/deployment/installer/agent/unix/default/latest/?Api-Token=my_paas_token&arch=all',
            path: '/tmp/Dynatrace-OneAgent-Linux-latest.sh',
            allow_insecure: false,
            creates: '/var/lib/dynatrace/oneagent/agent/config/agent.state',
            proxy_server: nil,
            cleanup: false,
            download_options: nil,
          )
      }
      it {
        is_expected.to contain_file('/tmp/dt-root.cert.pem')
          .with(
            ensure: 'file',
            mode: '0644',
            source: 'puppet:///modules/dynatraceoneagent/dt-root.cert.pem',
          )
      }
      it {
        is_expected.to contain_exec('verify_oneagent_installer')
          .with(
            command: %r{cat /tmp/Dynatrace-OneAgent-Linux-latest.sh},
            path: ['/usr/bin'],
            unless: '/usr/bin/test -f /var/lib/dynatrace/oneagent/agent/config/agent.state',
          )
      }
      it { is_expected.to contain_exec('verify_oneagent_installer').with(command: %r{-CAfile /tmp/dt-root.cert.pem}) }
      it { is_expected.to contain_exec('verify_oneagent_installer').that_requires('File[/tmp/dt-root.cert.pem]') }
      it { is_expected.to contain_exec('verify_oneagent_installer').that_requires('Archive[oneagent_installer]') }
      it { is_expected.to contain_exec('install_oneagent').that_requires('Exec[verify_oneagent_installer]') }
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
      it { is_expected.to contain_exec('install_oneagent').that_requires('Archive[oneagent_installer]') }
      it {
        is_expected.to contain_exec('delete_oneagent_installer_script')
          .with(
            command: 'rm /tmp/Dynatrace-OneAgent-Linux-latest.sh',
            path: ['/usr/bin'],
            onlyif: '/usr/bin/test -f /tmp/Dynatrace-OneAgent-Linux-latest.sh',
          )
      }
      it { is_expected.to contain_exec('delete_oneagent_installer_script').that_requires('Exec[install_oneagent]') }
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
      it { is_expected.to contain_file('/var/lib/dynatrace/oneagent/agent/config/puppet').that_requires('Exec[install_oneagent]') }
      it { is_expected.to contain_file('/var/lib/dynatrace/oneagent/agent/config/puppet/hostgroup.conf').with(ensure: 'absent') }
      it { is_expected.to contain_file('/var/lib/dynatrace/oneagent/agent/config/puppet/hostname.conf').with(ensure: 'absent') }
      it { is_expected.to contain_file('/var/lib/dynatrace/oneagent/agent/config/puppet/networkzone.conf').with(ensure: 'absent') }
      it { is_expected.to contain_file('/var/lib/dynatrace/oneagent/agent/config/puppet/logaccess.conf').with(ensure: 'absent') }
      it { is_expected.to contain_file('/var/lib/dynatrace/oneagent/agent/config/puppet/logmonitoring.conf').with(ensure: 'absent') }
      it { is_expected.to contain_file('/var/lib/dynatrace/oneagent/agent/config/puppet/infraonly.conf').with(ensure: 'absent') }
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
      it { is_expected.to contain_exec('set_host_group').that_requires('Exec[install_oneagent]') }
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
      it { is_expected.to contain_exec('set_hostname').that_requires('Exec[install_oneagent]') }
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
      it { is_expected.to contain_exec('set_monitoring_mode').that_requires('Exec[install_oneagent]') }
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
      it { is_expected.to contain_exec('set_network_zone').that_requires('Exec[install_oneagent]') }
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
      it { is_expected.to contain_exec('set_log_access').that_requires('Exec[install_oneagent]') }
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
      it { is_expected.to contain_exec('set_log_monitoring').that_requires('Exec[install_oneagent]') }
      it { is_expected.to contain_file('/var/lib/dynatrace/oneagent/agent/config/puppet/deployment.conf').with(ensure: 'absent') }
      it {
        is_expected.not_to contain_file('/var/lib/dynatrace/oneagent/agent/config/puppet/deployment.conf')
          .that_notifies('Exec[set_oneagent_communication]')
      }
      it { is_expected.to contain_exec('set_oneagent_communication').with(refreshonly: true) }

      it {
        is_expected.to contain_service('oneagent')
          .with(
            ensure: 'running',
            enable: true,
            hasstatus: true,
            hasrestart: true,
          )
      }
      it { is_expected.to contain_service('oneagent').that_requires('Exec[install_oneagent]') }

      context 'with "download_dir => /root/tmp"' do
        let(:params) do
          super().merge('download_dir' => '/root/tmp')
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file('/root/tmp').with(ensure: 'directory') }
        it { is_expected.to contain_archive('oneagent_installer').that_requires('File[/root/tmp]') }
        it { is_expected.to contain_file('/root/tmp/dt-root.cert.pem') }
        it {
          is_expected.to contain_exec('verify_oneagent_installer')
            .with(
              command: %r{cat /root/tmp/Dynatrace-OneAgent-Linux-latest.sh},
            )
        }
        it { is_expected.to contain_exec('verify_oneagent_installer').with(command: %r{-CAfile /root/tmp/dt-root.cert.pem}) }
        it { is_expected.to contain_exec('verify_oneagent_installer').that_requires('File[/root/tmp/dt-root.cert.pem]') }
      end

      context 'with "verify_signature => false"' do
        let(:params) do
          super().merge('verify_signature' => false)
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.not_to contain_exec('verify_oneagent_installer') }
        it { is_expected.not_to contain_file('/tmp/dt-root.cert.pem') }
      end

      context 'with "version => 1.181.63.20191105-161318"' do
        let(:params) do
          super().merge('version' => '1.181.63.20191105-161318')
        end

        it { is_expected.to compile.with_all_deps }
        it {
          is_expected.to contain_archive('oneagent_installer')
            .with(
              source: 'https://live.dynatrace.com/api/v1/deployment/installer/agent/unix/default/version/1.181.63.20191105-161318?Api-Token=my_paas_token&arch=all',
            )
        }
        it do
          install_command = catalogue.resource('Exec[install_oneagent]')[:command]
          expect(install_command).to include('/tmp/Dynatrace-OneAgent-Linux-1.181.63.20191105-161318.sh')
        end
        it {
          is_expected.to contain_exec('delete_oneagent_installer_script')
            .with(
              command: 'rm /tmp/Dynatrace-OneAgent-Linux-1.181.63.20191105-161318.sh',
              onlyif: '/usr/bin/test -f /tmp/Dynatrace-OneAgent-Linux-1.181.63.20191105-161318.sh',
            )
        }
        it { is_expected.to contain_exec('verify_oneagent_installer').with(command: %r{cat /tmp/Dynatrace-OneAgent-Linux-1.181.63.20191105-161318.sh}) }
      end

      context 'with "allow_insecure => true"' do
        let(:params) do
          super().merge('allow_insecure' => true)
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_archive('oneagent_installer').with(allow_insecure: true) }
      end

      context 'with "reboot_system => true"' do
        let(:params) do
          super().merge('reboot_system' => true)
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_exec('install_oneagent').that_notifies('Reboot[after]') }
        it { is_expected.to contain_reboot('after') }
      end

      context 'with "service_state => stopped"' do
        let(:params) do
          super().merge('service_state' => 'stopped')
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_service('oneagent').with(ensure: 'stopped', enable: false) }
      end

      context 'with "manage_service => false"' do
        let(:params) do
          super().merge('manage_service' => false)
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.not_to contain_service('oneagent') }
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
        it do
          install_command = catalogue.resource('Exec[install_oneagent]')[:command]
          expect(install_command).to include('--set-host-group=testgroup')
        end
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
        it do
          install_command = catalogue.resource('Exec[install_oneagent]')[:command]
          expect(install_command).to include('--set-host-name=testhost')
        end
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
        it do
          install_command = catalogue.resource('Exec[install_oneagent]')[:command]
          expect(install_command).to include('--set-network-zone=testzone')
        end
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
        it do
          install_command = catalogue.resource('Exec[install_oneagent]')[:command]
          expect(install_command).to include('--set-system-logs-access-enabled=false')
        end
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
