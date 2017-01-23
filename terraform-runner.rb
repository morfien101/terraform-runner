#!/usr/bin/ruby
require 'terraform_runner'

options = Options.get_options(ARGV)
logger = LoggerHelper.get_logger(options)
if InputChecker.new(options,logger).valid?
  runner = TerraformRunner.new(logger, options)
  runner.execute_commands()
  exit runner.tf_exit_code
end
