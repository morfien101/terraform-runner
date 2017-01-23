
# Modules for utilities that don't really belong to a specific class
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

  def self.command
    return LinuxCommand.new if OS.linux? || OS.mac?
    return WindowsCommand.new if OS.windows?
    raise 'Not a supported platform!'
  end

  # See if a program is in the path
  def self.locate(program_to_check)
    locate_command = self.windows? ? "where #{program_to_check}" : "which #{program_to_check}"
    location = `#{locate_command}`.chomp
    unless $CHILD_STATUS.success?
      puts 'Could not find the terraform binary in the path'
      exit 1
    end
    location = "\"#{location}\"" if OS.windows? && location.include?(" ")
    location
  end
end

# Gems for this file
# Placed here because we need OS.unix? to be created
require 'pty' if OS.unix?

module EXIT
  def self.fatal_error(logger, messages, exit_code)
    # TODO make a log level fatal
    messages = messages.join("\n") if messages.is_a?(Array)
    logger.warn(messages)
    exit exit_code
  end
end
