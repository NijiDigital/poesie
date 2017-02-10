module Poesie
  module ContextFormatter

    # Write the JSON output file containing all context keys
    #
    # @param [Array<Hash<String, Any>>] terms
    #        JSON returned by the POEditor API
    # @param [String] file
    #        The path of the file to write
    # @param [Regexp] exclude
    #        A regular expression to filter out terms.
    #        Terms matching this Regexp will be ignored and won't be part of the generated file
    #
    def self.write_context_json(terms, file, exclude: nil)

      json_hash = { "date" => "#{Time.now}" }

      stats = { :excluded => 0, :nil => 0, :count => 0 }

      #switch on term / context
      array_context = Array.new
      terms.each do |term|
        (term, definition, comment, context) = ['term', 'definition', 'comment', 'context'].map { |k| term[k] }

        # Filter terms and update stats
        next if (term.nil? || term.empty? || context.nil? || context.empty?) && stats[:nil] += 1
        next if (term =~ exclude) && stats[:excluded] += 1 # Remove android-specific strings

        stats[:count] += 1

        # Escape some chars
        context = context
                .gsub("\u2028", '') # Sometimes inserted by the POEditor exporter
                .gsub("\\", "\\\\\\") # Replace actual \ with \\
                .gsub('\\\\"', '\\"') # Replace actual \\" with \"
                .gsub(/%(\d+\$)?s/, '%\1@') # replace %s with %@ for iOS

        array_context << { "term" => "#{term}", "context" => "#{context}" }
      end

      json_hash[:"contexts"] = array_context

      context_json = JSON.pretty_generate(json_hash)

      Log::info(" - Save to file: #{file}")
      File.open(file, "w") do |fh|
        fh.write(context_json)
      end
      Log::info("   [Stats] #{stats[:count]} strings processed")
      unless exclude.nil?
        Log::info("   Filtered out #{stats[:excluded]} strings matching #{exclude.inspect})")
      end
    end
  end
end
