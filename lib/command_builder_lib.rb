require 'json'

class CommandBuilder
  def initialize(action, module_updates, config_file)
    @action = action
    @module_updates = module_updates
    @base_dir = Dir.pwd
    @config_file_data = convert_json_to_ruby(config_file)
  end

  # Gives us the location of the terraform bin file based on the running OS
  def terraform_bin
    OS.locate('terraform')
  end

  def convert_json_to_ruby(config_file)
    # Load the configuration file specified
    return JSON.parse(IO.read(File.join(@base_dir,config_file)))
  end

  def digest_inline_vars(vars)
    vars.map {|k,v|
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
      return join_text tf_action_command
    end

    tf_action_command << digest_inline_vars(@config_file_data['inline_variables'])
    tf_action_command << digest_var_files(@config_file_data['variable_path'],@config_file_data['variable_files'])
    tf_action_command << digest_custom_args(@config_file_data['custom_args'])

    # we need the detailed exit code to see if there is any changes that
    # need to be made to the environment.
    tf_action_command << '-detailed-exitcode' if @action == 'plan'
    tf_action_command << '-force' if @action == 'destroy'

    return join_text tf_action_command
  end

  def tf_state_file_cmd
    tf_state_file_command="#{terraform_bin} remote config -backend=#{@config_file_data['state_file']['type']}"
    @config_file_data['state_file']['config'].each {|k,v|
      tf_state_file_command += " -backend-config=\"#{k}=#{v}\""
    }
    return tf_state_file_command
  end

  private :join_text, :digest_inline_vars, :digest_var_files, :digest_custom_args
  private :convert_json_to_ruby, :terraform_bin
end
