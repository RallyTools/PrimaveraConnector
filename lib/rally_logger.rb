# Copyright 2002-2011 Rally Software Development Corp. All Rights Reserved.

require "logger"

# Tweak logger message format, with thanks to
# blog.grayproductions.net/articles/the_books_are_wrong_about_logger+ruby+logger+format
class CustomLogFormat < Logger::Formatter
  def call(severity, time, program_name, message)
    datetime = time.strftime("%Y-%m-%d %H:%M:%S")
    "[%s] %5s : %s\n" % [datetime, severity, message]
  end
end

class RallyLogger

  if ($DEBUG)
    @@logger = Logger.new(STDOUT)
  else
    # Keep 10, 5MB log files
    @@logger = Logger.new('primconn.log', 10, 5*1024*1024)
  end

  @@logger.formatter = CustomLogFormat.new # Install custom formatter
  @@logger.level = Logger::DEBUG

  def self.error(this, text)
    @@logger.error("#{context(this)} - " + text)
  end

  def self.warning(this, text)
    @@logger.warn("#{context(this)} - " + text)
  end

  def self.info(this, text)
    @@logger.info("#{context(this)} - " + text)
  end

  def self.debug(this, text)
    @@logger.debug("#{context(this)} - " + text)
  end

  def self.exception(this, ex)
    RallyLogger.error(this, "Message " + ex.message)
    RallyLogger.error(this, "Stack Trace")
    ex.backtrace.each { |trace| RallyLogger.error(this, trace) }
  end

  def self.logger
    @@logger
  end

  private

  #Thanks to http://snippets.dzone.com/posts/show/2787
  def self.parse_caller(at)
    if /^(.+?):(\d+)(?::in `(.*)')?/ =~ at
      file   = Regexp.last_match[1]
      line   = Regexp.last_match[2].to_i
      method = Regexp.last_match[3]
      [file, line, method]
    end
  end

  def self.context(this)
    return this.class.to_s + "." + parse_caller(caller(2).first).last
  end
end
