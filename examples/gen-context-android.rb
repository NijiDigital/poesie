#!/usr/bin/env ruby

unless ARGV.count >= 1
  puts "Usage: #{File.basename(__FILE__)} JSON_FILE"
  exit 1
end

### Parse the context.json file ##
require 'json'
json_string = File.read(ARGV[0])
json = JSON.parse(json_string)


### Loop on all contexts to generate the xml resources ###

json_context_values = []

json['contexts'].each do |item|
  json_context_values << %Q[    <string name="#{item['term']}_context" translatable="false">"#{item['context']}"</string>]
end

### Print the output in stdout ###

puts <<-OUTPUT
<?xml version="1.0" encoding="utf-8"?>
<!-- Exported from POEditor with script gen-context.rb -->
<resources>

#{json_context_values.join("\n")}

</resources>
OUTPUT
