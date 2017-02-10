require File.expand_path('log', File.dirname(__FILE__))
require File.expand_path('exporter', File.dirname(__FILE__))
require File.expand_path('filters', File.dirname(__FILE__))
require File.expand_path('android_formatter', File.dirname(__FILE__))
require File.expand_path('apple_formatter', File.dirname(__FILE__))
require File.expand_path('context_formatter', File.dirname(__FILE__))

require 'json'

module Poesie
  def self.exit_with_error(message)
    Log::error message
    exit 1
  end

  # Apply the list of text substitutions to the given string
  #
  # @param [String] text
  #        The text to process
  # @param [Hash<String,String>] substitutions
  #        The substitutions to apply
  #
  def self.process(text, substitutions)
    return text if substitutions.nil?
    replaced = text.dup
    list = substitutions
    list = [substitutions] if substitutions.is_a?(Hash)
    list.each do |hash|
      hash.each do |k,v|
        # If the key is surrounding by slashes, interpret as a RegExp
        k = Regexp.new($1) if k =~ %r(^/(.*)/$)
        replaced.gsub!(k, v)
      end
    end
    replaced
  end
end
