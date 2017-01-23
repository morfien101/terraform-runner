class InputChecker
  def initialize(options,logger)
    @logger = logger
    @options = options
    @errors = []
  end

  def input_check
    @errors << validate_config_file_supplied(@options[:config_file])
    @errors << validate_action(@options[:action])
    # Print errors and exit if there are errors
  end

  def validate_config_file_supplied(config_file)
    # We require a config file to do error checking.
    return 'You have not supplied a config file.' if config_file.nil?
    @logger.debug("Path to the config file: #{config_file}")

    return validate_config_file_exist(config_file)
  end

  def validate_config_file_exist(config_file)
    return 'The config file path seems to be missing or not valid.' unless File.exist?(config_file)
  end

  def validate_action(action)
    # Tests to check user in put
    @logger.debug('Checking the user input')
    return "Invalid action: #{action}" unless Options::VALID_ACTIONS.include?(action.downcase)
  end

  def valid?
    input_check
    if @errors.compact.empty?
      return true
    else
      EXIT.fatal_error(@logger,@errors, 1)
    end
  end
end
