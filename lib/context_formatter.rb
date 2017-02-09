module Poesie
  module ContextFormatter

    # Write the JSON output file containing all context keys
    #
    # @param [Array<Hash<String, Any>>] terms
    #        JSON returned by the POEditor API
    # @param [String] file
    #        The path of the file to write
    #
    def self.write_context_json(terms, file, currentOS)

      json_hash = { "date" => "#{Time.now}" }

      stats = { :filteredOS => 0, :nil => 0, :count => 0 }

      #switch on term / context
      array_context = Array.new
      terms.each do |term|
        (term, definition, comment, context) = ['term', 'definition', 'comment', 'context'].map { |k| term[k] }

        # Filter terms and update stats
        next if (term.nil? || term.empty? || context.nil? || context.empty?) && stats[:nil] += 1
        if currentOS == CurrentOS::ANDROID
          next if (term =~ /_ios$/) && stats[:filteredOS] += 1 # Remove android-specific strings
        elsif currentOS == CurrentOS::IOS
          next if (term =~ /_android$/) && stats[:filteredOS] += 1 # Remove android-specific strings
        end

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
      if currentOS == CurrentOS::ANDROID
        Log::info("   [Stats] #{stats[:count]} contexts processed (Filtered out #{stats[:filteredOS]} ios entries, #{stats[:nil]} nil contexts)")
      elsif CurrentOS == CurrentOS::IOS
        Log::info("   [Stats] #{stats[:count]} contexts processed (Filtered out #{stats[:filteredOS]} android entries, #{stats[:nil]} nil contexts)")
      end
    end
  end
end
