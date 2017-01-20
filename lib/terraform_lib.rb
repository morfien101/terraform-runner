#!/usr/bin/ruby
require_relative 'command_builder_lib'
require_relative 'modules_lib'
require_relative 'command_lib'
require_relative 'options_lib'
require_relative 'logger_lib'

require 'json'
require 'logger'
require 'fileutils'
require 'time'
require 'english'
require 'pty' if OS.unix?

# Set some base variables
VERSION='0.1.0'.freeze

class Terraform_runner
  # This is used to hold the value of the terraform exit code from the run.
  # Mostly useful during the plan runs.
  attr_reader :tf_exit_code

  def initialize(logger, options, cmd_builder)
    @tf_exit_code = 0
    @base_dir = Dir.pwd
    @logger = logger
    @debug = options[:debug]
    @config_file = options[:config_file]
    @action = options[:action]
    @execute_silently = options[:silent]
    @module_updates = options[:module_updates]
    @cmd_builder = cmd_builder
  end

  def execute_commands()
    # Preflight checks
    input_check

    ## Is the directory there?
    # Create a unique directory each time.
    working_dir = create_working_directory

    # Copy the source files into the running dir
    copy_files_to_working_directory(working_dir)

    # Create the remote state files.
    @logger.debug('move into the working dir')
    Dir.chdir working_dir

    @logger.debug("build up terraform remote state file command: #{@cmd_builder.tf_state_file_cmd}")
    # Build up the terraform action command
    @logger.debug("Build up Terraform action command: #{@cmd_builder.tf_action_cmd}")
    prompt_to_destroy() unless @execute_silently && @action == 'delete'
    run_commands
  end

  private

  def create_working_directory()
    # Create/Clean the working directory
    @logger.debug('Setup working directory')
    epoch=Time.now().to_i
    working_dir=File.expand_path(File.join(@base_dir,"terraform-runner-working-dir-#{epoch}"))
    @logger.debug("Create directory #{working_dir}")
    make_working_dir(working_dir)
    working_dir
  end

  def copy_files_to_working_directory(working_dir)
    @logger.debug('Ship souce code to the running folder')
    FileUtils.cp_r("#{File.expand_path(File.join(@base_dir,@config_file_data['tf_file_path']))}/.", working_dir,:verbose => @debug)
  end

  def fatal_error(messages, exit_code)
    puts '==Fatal Error'
    messages = messages.join("\n") if messages.is_a?(Array)
    puts messages
    exit exit_code
  end

  def input_check()
    errors=[]
    validate_config_file()
    validate_action()

    # We need to open the file now and error check that
    @config_file_data = convert_json_to_ruby(@config_file)
    @logger.debug("Collected config file: #{@config_file_data}")

    ## Is the directory and files stated in the config file available.
    @logger.debug('Is the variable file there?')
    @config_file_data['variable_files'].each{ |var_file|
      full_path=File.expand_path(File.join(@base_dir,@config_file_data['variable_path'],var_file))
      if !File.exists?(full_path)
        errors << "File not found #{full_path}"
      end
    } unless @config_file_data['variable_files'].nil?
    @logger.debug('Is the source code dir there?')
    full_path=File.expand_path(File.join(@base_dir,@config_file_data['tf_file_path']))
    if !File.directory?(full_path)
      errors << "Could not find source code directory: #{full_path}"
    end
    # Print errors and exit if there are errors
    fatal_error(errors, 1) unless errors.empty?
  end
  
  def validate_config_file()
    # We require a config file to do error checking.
    # Fix: avoid dumping back trace?
    fatal_error('You have not supplied a config file.', 1) if @config_file.nil?
    @logger.debug("Path to the config file: #{@config_file}")
    fatal_error('The config file path seems to be missing or not valid.', 1) unless File.exist?(@config_file)
  end

  def validate_action()
    # Tests to check user in put
    @logger.debug('Checking the user input')
    errors << "Invalid action: #{@action}" unless Options::VALID_ACTIONS.include?(@action.downcase)
  end

  def convert_json_to_ruby(config_file)
    # Load the configuration file specified
    return JSON.parse(IO.read(File.join(@base_dir,config_file)))
  end

  def make_working_dir(dir)
    FileUtils::mkdir_p dir
  end

  def prompt_to_destroy()
    puts %q<Please type 'yes' to destroy your stack. Only yes will be accepted.>
    input=gets.chomp
    return if input == 'yes'
    puts "#{input} was not accepted. Exiting for safety!"
    exit 1
  end

	def run_commands
    cmd = OS.command
		# Running the commands depending on OS.
		# Linux allows us to use a Pessudo shell, This will stream the output
		# Windows has to execute in a subprocess and puts the STDOUT at the end.
		# This can lead to a long wait before seeing anything in the console.
    @logger.debug('Run the terraform state file command.')
    cmd.run_command(@cmd_builder.tf_state_file_cmd)
		# Run the action specified
    @logger.debug('Run the terraform action command.')
    @tf_exit_code = cmd.run_command(@cmd_builder.tf_action_cmd)
	end
end
