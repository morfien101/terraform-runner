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
      @logger.fatal('The child proesses exited!')
    end
  end
end
