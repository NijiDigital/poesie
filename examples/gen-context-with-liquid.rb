#!/usr/bin/env ruby

begin
  require 'liquid'
rescue LoadError => e
  stderr.puts %q(Failed to load the Liquid gem. Use `gem install liquid -v '~> 3.0'` to install it first.)
end
require 'json'

unless ARGV.count >= 2
  puts "Usage: #{File.basename(__FILE__)} JSON_FILE LIQUID_TEMPLATE_FILE"
  exit 1
end

json_string = File.read(ARGV[0])
json = JSON.parse(json_string)

template_string = File.read(ARGV[1])

# Declare some custom Liquid Filters used by the template, then render it
module CustomFilters
  def escape_quotes(input)
    return input.gsub('"', '\"')
  end
  def snake_to_camel_case(input)
    input.split('_').map { |s| s.capitalize }.join
  end
  def uncapitalize(input)
    input[0, 1].downcase + input[1..-1]
  end
end

template = Liquid::Template.parse(template_string)
puts template.render(json, :filters => [CustomFilters]).gsub(/^ +$\n/,'')
