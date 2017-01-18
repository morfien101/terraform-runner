#!/usr/bin/ruby
require 'json'
require 'optparse'
require 'logger'
require 'fileutils'
require 'time'

# Set some base variables
VERSION="0.0.4".freeze

module OS
  def self.windows?
    (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
  end

  def self.mac?
   (/darwin/ =~ RUBY_PLATFORM) != nil
  end

  def self.unix?
    !self.windows?
  end

  def self.linux?
    (/linux|arch/ =~ RUBY_PLATFORM) != nil
  end

  def self.get_command
  	return LinuxCommand.new if OS.linux? || OS.mac?
  	return WindowsCommand.new if OS.windows?
  	raise "Not a supported platform!"
  end
end

require 'pty' if OS.unix?
require 'english' if OS.windows?

# Gather the options
class Options
	VALID_ACTIONS=["plan", "apply", "destroy","get"]
	def self.get_options
		options=Hash.new
		OptionParser.new do |opts|
			opts.banner = "Usage: terraform-runner.rb [options]"
			opts.separator ""
		    opts.separator "Specific options:"

		    # Set some defaults
		    options[:silent] = false
		    options[:action] = "plan"
		    options[:debug] = false
		    options[:create_json] = false
		    options[:module_updates] = false

		    # Get the options flags
		    opts.on("-c", "--config-file /path/to/file", String, "Path to config JSON file") do |config|
		    	options[:config_file] = config
		    end

		    opts.on("-a", "--action action_type", String, "Terraform action: #{VALID_ACTIONS.join(', ')}") do |action|
		    	options[:action] = action
		    end

		    opts.on("--update-modules", "Forces updates of modules. Only to be used with the get action.") do
		    	options[:module_updates] = true
		    end

		    opts.on("-f", "--force", "No prompts") do |force|
		    	options[:silent] = true
		    end

		    opts.on("--json-example", "Prints default JSON file.") do
		    	puts '{'
				puts '	"environment": "Running Environment",'
				puts '	"tf_file_path":"path/",'
				puts '	"variable_path":"path/",'
				puts '	"variable_files":["vars1.tfvars","vars2.tfvar"],'
				puts '	"inline_variables":{'
				puts '		"aws_ssh_key_path":"${ENV[\'AWS_SSH_KEY_PATH\']}",'
				puts '		"aws_ssh_key_name": "myawskey"'
				puts '	},'
				puts '	"state_file":{'
				puts '		"type":"s3",'
				puts '		"config": {'
				puts '			"region":"eu-west-1",'
				puts '			"bucket":"terraform-bucket",'
				puts '			"key":"path/to/terraform-state.tfstate"'
				puts '		}'
				puts '	},'
				puts '	"custom_args":["-parallelism=10"]'
				puts '}'
				exit 0
		    end

		    opts.on("-h", "--help", "Displays this screen") do
		    	puts opts
		    	exit 0
		    end

		    opts.on("-v", "--version", "Display the version") do
		    	puts VERSION
		    	exit 0
		    end

		    opts.on("--debug") do
		    	options[:debug] = true
		    end
		end.parse!

		return options
	end
end

class Terraform_runner
	# This is used to hold the value of the terraform exit code from the run.
	# Mostly useful during the plan runs.
	attr_reader :tf_exit_code

	def initialize(options)
    @tf_exit_code = 0
		@options=options
		@base_dir=Dir.pwd

		#Setup logging
		@logger=Logger.new(STDOUT)
		#Turn on debug logger if required
		@logger.level=@options[:debug] ?  Logger::DEBUG : Logger::WARN
		@logger.formatter = proc do |severity, datetime, progname, msg|
  			"#{severity[0]} - #{datetime}: #{msg}\n"
		end

		# Preflight checks
		input_check()

		# Create/Clean the working directory
		@logger.debug("Setup working directory")
		## Is the directory there?
		# Create a unique directory each time.
    epoch=Time.now().to_i
		working_dir=File.expand_path(File.join(@base_dir,"terraform-runner-working-dir-#{epoch}"))
		@logger.debug("Create directory #{working_dir}")
		make_working_dir(working_dir)
		# Copy the source files into the running dir
		@logger.debug("Ship souce code to the running folder")
		FileUtils.cp_r("#{File.expand_path(File.join(@base_dir,@config_file_data['tf_file_path']))}/.", working_dir,:verbose => @options[:debug])

		# Create the remote state files.
		@logger.debug("move into the working dir")
		Dir.chdir working_dir

		@logger.debug("build up terraform remote state file command: #{tf_state_file_cmd}")
		# Build up the terraform action command
		@tf_action_built_command = tf_action_cmd
		@logger.debug("Build up Terraform action command: #{@tf_action_built_command}")

		run_commands
	end

	def fatal_error(messages,exit_code)
		puts "!!! Fatal Error !!!"
		if messages.is_a?(String)
			puts messages
		elsif messages.is_a?(Array)
			messages.each{|message|
				puts message
			}
		end
		exit exit_code
	end

	def input_check()
		errors=Array.new
		# We require a config file to do error checking.
		# Fix: avoid dumping back trace?
		fatal_error("You have not supplied a config file.", 1) if @options[:config_file].nil?
		@logger.debug("Path to the config file: #{@options[:config_file]}")
		fatal_error("The config file path seems to be missing or not valid.", 1) unless File.exist?(@options[:config_file])

		# Tests to check user in put
		@logger.debug("Checking the user input")
		errors << "Invalid action: #{@options[:action]}" unless Options::VALID_ACTIONS.include?(@options[:action].downcase)

		# We need to open the file now and error check that
		@config_file_data = convert_json_to_ruby(@options[:config_file])
		@logger.debug("Collected config file: #{@config_file_data}")

		## Is the directory and files stated in the config file available.
		@logger.debug("Is the variable file there?")
		@config_file_data['variable_files'].each{ |var_file|
			full_path=File.expand_path(File.join(@base_dir,@config_file_data['variable_path'],var_file))
			if !File.exists?(full_path)
				errors << "File not found #{full_path}"
			end
		} unless @config_file_data['variable_files'].nil?
		@logger.debug("Is the source code dir there?")
		full_path=File.expand_path(File.join(@base_dir,@config_file_data['tf_file_path']))
		if !File.directory?(full_path)
			errors << "Could not find source code directory: #{full_path}"
		end
		# Print errors and exit if there are errors
		fatal_error(errors, 1) unless errors.empty?
	end

	def convert_json_to_ruby(config_file)
		# Load the configuration file specified
		return JSON.parse(IO.read(File.join(@base_dir,config_file)))
	end

	## Is terraform available?
	def locate_terrafrom(locate_command)
		location = `#{locate_command} terraform`
		if !$?.success?
			puts "Could not find the terraform binary in the path"
			exit 1
		end
		return location.chomp
	end

	def terraform_bin
		if OS.linux? || OS.mac?
			terraform_bin = locate_terrafrom("which")
		elsif OS.windows?
			terraform_bin = "\"#{locate_terrafrom("where")}\""
		end
		return terraform_bin
	end

	def make_working_dir(dir)
		FileUtils::mkdir_p dir
	end

	def tf_state_file_cmd
		tf_state_file_command="#{terraform_bin} remote config -backend=#{@config_file_data['state_file']['type']} "
		@config_file_data['state_file']['config'].each {|k,v|
			tf_state_file_command += " -backend-config=\"#{k}=#{v}\""
		}
		return tf_state_file_command
	end

	def inline_vars(name,value)
		# We only want to run ENV here.
		if value =~ /^\$\{ENV/
			value=eval(value.gsub("${","").gsub("}",""))
		end
		return "-var #{name}=#{value} "
	end

	def var_files(file_path,file_name)
		return "-var-file=\"#{File.join(@base_dir,file_path,file_name)}\" "
	end

	def tf_action_cmd
		tf_action_command = "terraform #{@options[:action]} "

    # we need the detailed exit code to see if there is any changes that
    # need to be made to the environment.
    if @options[:action] == "plan"
      tf_action_command << " -detailed-exitcode "
    end

		if @options[:action] == "get"
			tf_action_command << " -update" if @options[:module_updates]
			return tf_action_command
		end

		@config_file_data['inline_variables'].each {|k,v|
			tf_action_command += inline_vars(k,v)
		} unless @config_file_data['inline_variables'].nil? || @config_file_data['inline_variables'].empty?

		@config_file_data['variable_files'].each { |file|
			tf_action_command += var_files(@config_file_data['variable_path'],file)
		} unless @config_file_data['variable_files'].nil? || @config_file_data['variable_files'].empty?

		tf_action_command += @config_file_data['custom_args'].map{|arg| " #{arg}"}.join unless @config_file_data['custom_args'].nil?

		if @options[:action] == "destroy" && !@options[:silent]
			puts "Please type 'yes' to destroy your stack. Only yes will be accepted."
			input=gets.chomp
			if input == "yes"
				tf_action_command += " -force"
			else
				puts "#{input} was not accepted. Exiting for safty!"
				exit 1
			end
		elsif @options[:action] == "destroy" && @options[:silent]
			tf_action_command += " -force"
		end

		return tf_action_command
	end

	def run_commands
		cmd=OS.get_command
		# Running the commands depending on OS.
		# Linux allows us to use a Pessudo shell, This will stream the output
		# Windows has to execute in a subprocess and puts the STDOUT at the end.
		# This can lead to a long wait before seeing anything in the console.
		@logger.debug("Run the terraform state file command.")
		cmd.run_command(tf_state_file_cmd)
		# Run the action specified
		@logger.debug("Run the terraform action command.")
		@tf_exit_code = cmd.run_command(@tf_action_built_command)
	end
end

class WindowsCommand
	def run_command(command_text)
		command_output=`#{command_text}`
		puts command_output
		return $CHILD_STATUS.exitstatus
	end
end

class LinuxCommand
	def run_command(command_text)
    # There is 2 places that this code will exit.
    # 1) if the command runs successfully then it will return the exit code.
    # 2) if the command failed it will run then rescue PTY::ChildExited block
		begin
			PTY.spawn(command_text) do |stdout, stdin,pid|
				begin
					stdout.each{|line| puts line}
				rescue Errno::EIO
          unless (ec = PTY.check(pid, false)).nil?
            return ec.exitstatus
          end
				end
			end
		rescue PTY::ChildExited
			@logger.fatal "The child proesses exited!"
		end
	end
end

exit Terraform_runner.new(Options.get_options).tf_exit_code
