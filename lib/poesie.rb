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

  # Apply the list of text replacements to the given string
  #
  # @param [String] text
  #        The text to process
  # @param [Hash<String,String>] replacements
  #        The replacements to apply
  #
  def self.process(text, replacements)
    return text if replacements.nil?
    replaced = text.dup
    replacements.each do |k,v|
      # If the key is surrounding by slashes, interpret as a RegExp
      k = Regexp.new($1) if k =~ %r(^/(.*)/$)
      replaced.gsub!(k, v)
    end
    replaced
  end
end
