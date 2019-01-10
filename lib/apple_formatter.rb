require 'builder'

module Poesie
  module AppleFormatter

    # Write the Localizable.strings output file
    #
    # @param [Array<Hash<String, Any>>] terms
    #        JSON returned by the POEditor API
    # @param [String] file
    #        The path of the file to write
    # @param [Hash<String,String>] substitutions
    #        The list of substitutions to apply to the translations
    # @param [Bool] print_date
    #        Should we print the date in the header of the generated file
    # @param [Regexp] exclude
    #        A regular expression to filter out terms.
    #        Terms matching this Regexp will be ignored and won't be part of the generated file
    #
    def self.write_strings_file(terms, file, substitutions: nil, print_date: false, exclude: Poesie::Filters::EXCLUDE_ANDROID)
      out_lines = ['/'+'*'*79, ' * Exported from POEditor - https://poeditor.com']
      out_lines << " * #{Time.now}" if print_date
      out_lines += [' '+'*'*79+'/', '']
      last_prefix = ''
      stats = { :excluded => 0, :nil => [], :count => 0 }

      terms.each do |term|
        (term, definition, comment, context) = ['term', 'definition', 'comment', 'context'].map { |k| term[k] }

        # Filter terms and update stats
        next if (term.nil? || term.empty? || definition.nil? || definition.empty?) && stats[:nil] << term
        next if (term =~ exclude) && stats[:excluded] += 1
        stats[:count] += 1

        # Generate MARK from prefixes
        prefix = %r(([^_]*)_.*).match(term)
        if prefix && prefix[1] != last_prefix
          last_prefix = prefix[1]
          mark = last_prefix[0].upcase + last_prefix[1..-1].downcase
          out_lines += ['', '/'*80, "// MARK: #{mark}"]
        end

        # If definition is a Hash, use the text for "one" if available (singular in languages using plurals)
        # otherwise (e.g. asian language where only key in hash will be "other", not "one"), then use the first entry
        if definition.is_a? Hash
          definition = definition["one"] || definition.values.first
        end

        definition = Poesie::process(definition, substitutions)
                    .gsub("\u2028", '') # Sometimes inserted by the POEditor exporter
                    .gsub("\n", '\n') # Replace actual CRLF with '\n'
                    .gsub('"', '\\"') # Escape quotes
                    .gsub(/%(\d+\$)?s/, '%\1@') # replace %s with %@ for iOS
        out_lines << %Q(// CONTEXT: #{context.gsub("\n", '\n')}) unless context.empty?
        out_lines << %Q("#{term}" = "#{definition}";)
      end

      content = out_lines.join("\n") + "\n"

      Log::info(" - Save to file: #{file}")
      File.open(file, "w") do |fh|
        fh.write(content)
      end
      Log::info("   [Stats] #{stats[:count]} strings processed")
      unless exclude.nil?
        Log::info("   Filtered out #{stats[:excluded]} strings matching #{exclude.inspect})")
      end
      unless stats[:nil].empty?
        Log::error("   Found #{stats[:nil].count} empty value(s) for the following term(s):")
        stats[:nil].each { |key| Log::error("    - #{key.inspect}") }
      end
    end

    # Write the Localizable.stringsdict output file
    #
    # @param [Array<Hash<String, Any>>] terms
    #        JSON returned by the POEditor API
    # @param [String] file
    #        The path of the file to write
    # @param [Hash<String,String>] substitutions
    #        The list of substitutions to apply to the translations
    # @param [Bool] print_date
    #        Should we print the date in the header of the generated file
    # @param [Regexp] exclude
    #        A regular expression to filter out terms.
    #        Terms matching this Regexp will be ignored and won't be part of the generated file
    #
    def self.write_stringsdict_file(terms, file, substitutions: nil, print_date: false, exclude: Poesie::Filters::EXCLUDE_ANDROID)
      stats = { :excluded => 0, :nil => [], :count => 0 }

      Log::info(" - Save to file: #{file}")
      File.open(file, "w") do |fh|
        xml_builder = Builder::XmlMarkup.new(:target => fh, :indent => 4)
        xml_builder.instruct!
        xml_builder.comment!("Exported from POEditor   ")
        xml_builder.comment!(Time.now) if print_date
        xml_builder.comment!("see https://poeditor.com ")
        xml_builder.plist(:version => '1.0') do |plist_node|
          plist_node.dict do |root_node|
            terms.each do |term|
              (term, term_plural, definition) = ['term', 'term_plural', 'definition'].map { |k| term[k] }

              # Filter terms and update stats
              next if (term.nil? || term.empty? || definition.nil?) && stats[:nil] << term
              next if (term =~ exclude) && stats[:excluded] += 1
              next unless definition.is_a? Hash
              stats[:count] += 1

              key = term_plural || term

              root_node.key(key)
              root_node.dict do |dict_node|
                dict_node.key('NSStringLocalizedFormatKey')
                dict_node.string('%#@format@')
                dict_node.key('format')
                dict_node.dict do |format_node|
                  format_node.key('NSStringFormatSpecTypeKey')
                  format_node.string('NSStringPluralRuleType')
                  format_node.key('NSStringFormatValueTypeKey')
                  format_node.string('d')

                  definition.each do |(quantity, text)|
                    text = Poesie::process(text, substitutions)
                    text = Poesie::process(text, substitutions)
                              .gsub("\u2028", '') # Sometimes inserted by the POEditor exporter
                              .gsub('\n', "\n") # Replace '\n' with actual CRLF
                              .gsub(/%(\d+\$)?s/, '%\1@') # replace %s with %@ for iOS
                    format_node.key(quantity)
                    format_node.string(text)
                  end
                end
              end
            end
          end
        end
      end

      Log::info("   [Stats] #{stats[:count]} strings processed")
      unless exclude.nil?
        Log::info("   Filtered out #{stats[:excluded]} strings matching #{exclude.inspect})")
      end
      unless stats[:nil].empty?
        Log::error("   Found #{stats[:nil].count} empty value(s) for the following term(s):")
        stats[:nil].each { |key| Log::error("    - #{key.inspect}") }
      end
    end
  end
end
