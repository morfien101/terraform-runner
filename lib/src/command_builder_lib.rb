class CommandBuilder
  def initialize(action, module_updates, config_file, logger)
    @action = action
    @module_updates = module_updates
    @base_dir = Dir.pwd
    @config_file = config_file
    @logger = logger
  end

  # Gives us the location of the terraform bin file based on the running OS
  def terraform_bin
    OS.locate('terraform')
  end

  def digest_inline_vars(vars)
    vars.map {|k,v|
      # TODO moved to the ConfigFile class
      if v =~ /^\$\{ENV/
        v=eval(v.gsub("${","").gsub("}",""))
      end
      "-var #{k}=#{v}"
    }.join(" ") unless vars.nil? || vars.empty?#
  end

  def digest_var_files(path,files)
    files.map { |file|
      "-var-file=\"#{File.join(@base_dir,path,file)}\""
    }.join(" ") unless files.nil? || files.empty?
  end

  def digest_custom_args(args)
    args.join(" ") unless args.nil?
  end

  def join_text(array)
    array.join(" ")
  end

  def tf_action_cmd
    tf_action_command = []
    tf_action_command << "#{terraform_bin} #{@action}"
    # Early return if action is get because we don't need the rest
    if @action == 'get'
      tf_action_command << '-update' if @module_updates
      @logger.debug("Running command: #{tf_action_command}")
      return join_text tf_action_command
    end

    tf_action_command << digest_inline_vars(@config_file.inline_variables)
    tf_action_command << digest_var_files(@config_file.variable_path,@config_file.variable_files)
    tf_action_command << digest_custom_args(@config_file.custom_args)

    # we need the detailed exit code to see if there is any changes that
    # need to be made to the environment.
    tf_action_command << '-detailed-exitcode' if @action == 'plan'
    tf_action_command << '-force' if @action == 'destroy'

    @logger.debug("Running command: #{tf_action_command}")
    return join_text tf_action_command
  end

  def tf_state_file_cmd
    tf_state_file_command="#{terraform_bin} remote config -backend=#{@config_file.state_file['type']}"
    @config_file.state_file['config'].each {|k,v|
      tf_state_file_command += " -backend-config=\"#{k}=#{v}\""
    }
    @logger.debug("Running command: #{tf_state_file_command}")
    return tf_state_file_command
  end

  private :join_text, :digest_inline_vars, :digest_var_files, :digest_custom_args
  private :terraform_bin
end
