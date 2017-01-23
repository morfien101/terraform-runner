#!/usr/bin/ruby


class TerraformRunner
  # This is used to hold the value of the terraform exit code from the run.
  # Mostly useful during the plan runs.
  attr_reader :tf_exit_code

  def initialize(logger, options)
    @tf_exit_code = 0
    @base_dir = Dir.pwd
    @logger = logger
    @debug = options[:debug]
    @config_file = ConfigFile.new(options[:config_file], logger)
    @action = options[:action]
    @execute_silently = options[:silent]
    @module_updates = options[:module_updates]
    @cmd_builder = CommandBuilder.new(options[:action], options[:module_updates], @config_file, logger)
  end

  def execute_commands()
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
    prompt_to_destroy()
    run_commands
  end

  def create_working_directory
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
    FileUtils.cp_r("#{File.expand_path(File.join(@base_dir,@config_file.tf_file_path))}/.", working_dir,:verbose => @debug)
  end

  def make_working_dir(dir)
    FileUtils::mkdir_p dir
  end

  def prompt_to_destroy()
     if @action.downcase == 'destroy' && !@execute_silently
      puts %q<Please type 'yes' to destroy your stack. Only yes will be accepted.>
      input=gets.chomp
      return if input == 'yes'
      puts "#{input} was not accepted. Exiting for safety!"
      exit 1
    end
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

  private :run_commands, :prompt_to_destroy, :make_working_dir, :copy_files_to_working_directory
  private :create_working_directory
end
