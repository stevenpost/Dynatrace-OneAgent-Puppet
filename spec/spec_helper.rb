# frozen_string_literal: true

# Managed by modulesync - DO NOT EDIT
# https://gitlab.sfpd.fgov.be/cbi/modulesync-config

require 'voxpupuli/test/spec_helper'

# Remove the parent's coverage hook if it exists
RSpec.configuration.instance_variable_get(:@after_suite_hooks).clear

require 'spec_helper_local' if File.file?(File.join(File.dirname(__FILE__), 'spec_helper_local.rb'))

default_facts = YAML.safe_load(File.read(File.expand_path(File.join(__FILE__, '../default_facts.yml'))))

default_facts.each do |fact, value|
  add_custom_fact fact, value, merge_facts: true
end

RSpec.configure do |c|
  c.default_facts = default_facts
  c.hiera_config = File.expand_path(File.join(__FILE__, '../fixtures/hiera.yaml'))
  c.after(:suite) do
    RSpec::Puppet::Coverage.report!(100)
  end
end

# 'spec_overrides' from .sync.yml will appear below this line
