require 'logger'

class LoggerHelper
  def self.get_logger(options)
    #Setup logging
    logger=Logger.new(STDOUT)
    #Turn on debug logger if required
    logger.level=options[:debug] ?  Logger::DEBUG : Logger::WARN
    logger.formatter = proc do |severity, datetime, _, msg|
      "#{severity[0]} - #{datetime}: #{msg}\n"
    end
    logger
  end
end
