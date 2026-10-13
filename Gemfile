# frozen_string_literal: true

# Managed by modulesync - DO NOT EDIT
# https://gitlab.sfpd.fgov.be/cbi/modulesync-config

source ENV['GEM_SOURCE'] || 'https://rubygems.org'

group :test do
  gem 'csv', '~> 3.3',             :require => false
  gem 'puppet_metadata', '~> 6.3', :require => false
  gem 'rexml', '~> 3.4',           :require => false
  gem 'voxpupuli-test', '~> 14.0', :require => false
end

gem 'rake', :require => false

gem 'openvox', ENV.fetch('OPENVOX_GEM_VERSION', [">= 8", "< 9"]), :require => false, :groups => [:test]
