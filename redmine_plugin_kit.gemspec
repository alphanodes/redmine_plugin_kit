# frozen_string_literal: true

require_relative 'lib/redmine_plugin_kit/version'
lib = File.expand_path '../lib', __FILE__
$LOAD_PATH.unshift lib unless $LOAD_PATH.include? lib

Gem::Specification.new do |spec|
  spec.name          = 'redmine_plugin_kit'
  spec.version       = RedminePluginKit::VERSION
  spec.authors       = ['AlphaNodes']
  spec.email         = ['alex@alphanodes.com']
  spec.metadata      = { 'rubygems_mfa_required' => 'true' }

  spec.summary       = 'Redmine plugin kit'
  spec.description   = 'Redmine plugin kit as base of Redmine plugins'
  spec.homepage      = 'https://github.com/alphanodes/redmine_plugin_kit'
  spec.license       = 'GPL-2.0'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match %r{^((test|spec|features)/|Gemfile)}
  end
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.7'

  spec.add_dependency 'deface', '1.9.0'
  spec.add_dependency 'rails'
end
