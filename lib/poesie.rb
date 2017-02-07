require File.expand_path('utils/log', File.dirname(__FILE__))

require File.expand_path('exporter', File.dirname(__FILE__))
require File.expand_path('android_formatter', File.dirname(__FILE__))
require File.expand_path('apple_formatter', File.dirname(__FILE__))

require 'json'

module Poesie
  def self.exit_with_error(message)
    Log::error message
    exit 1
  end
end
