#!/usr/bin/ruby
require_relative 'lib/terraform_lib'

options = Options.get_options(ARGV)
if ARGV.length >= 2
  logger = LoggerHelper.get_logger
  cmd_builder = CommandBuilder.new(options[:action], options[:module_updates], options[:config_file_data])
  runner = Terraform_runner.new(logger, options, cmd_builder)
  runner.execute_commands()
  exit runner.tf_exit_code
end
