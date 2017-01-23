# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'src/version'

Gem::Specification.new do |spec|
  spec.name          = "terraform_runner"
  spec.version       = TerraformRunner::VERSION
  spec.authors       = ["Randy Coburn"]
  spec.email         = ["morfien101@gmail.com"]

  spec.summary       = %q{This gem allows you to wrap Hashi Corps Terraform in to a repeatable process. }
  spec.description   = %q{More documentation can be found on https://github.com/morfien101/terraform-runner }
  spec.homepage      = "https://github.com/morfien101/terraform-runner"
  spec.license       = 'GPL-3.0'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files = Dir['{lib}/**/*', 'README*', 'LICENSE*']
  spec.require_paths = ["lib"]
end
