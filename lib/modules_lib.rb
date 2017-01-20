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
    location = `#{locate_command}`
    unless $CHILD_STATUS.success?
      puts 'Could not find the terraform binary in the path'
      exit 1
    end
    return location.chomp
  end
end
