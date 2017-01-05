#!/bin/env ruby

unless ARGV.count >= 1
  puts "Usage: #{File.basename(__FILE__)} JSON_FILE"
  exit 1
end

### Parse the Context.json ##
require 'json'
json_string = File.read(ARGV[0])
json = JSON.parse(json_string)

### Some utility functions ##
def case_name(item)
  # Use the item's term, transform the snake_case to CamelCase, then to lowerCamelCase
  str = item['term'].split('_').map { |s| s.capitalize }.join
  return str[0, 1].downcase + str[1..-1]
end
def escape_quotes(input)
  return input.gsub('"', '\"')
end

### Loop on all contexts to generate the various case lines ###
(json_error_cases, switch_cases) = [[], []]
json['contexts'].each do |item|
  json_error_cases << %Q[  case #{case_name(item)} = "#{escape_quotes(item['context'])}"]
  switch_cases << %Q[    case .#{case_name(item)}:\n      return "#{escape_quotes(item['term'])}"]
end


### Print the output in stdout ###
puts <<-OUTPUT
/*******************************************************************************
 * Exported from POEditor - https://poeditor.com
 * #{json['date']}
 *******************************************************************************/

enum JsonError: String, ErrorType {
#{json_error_cases.join("\n")}
}

extension JsonError {
  var localizedMessage: String {
    return NSLocalizedString(self.localizedKey, "")
  }

  var localizedKey: String {
    switch self {
#{switch_cases.join("\n")}
    }
  }
}
OUTPUT
