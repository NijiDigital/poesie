require 'builder'

module Poesie
  module AndroidFormatter

    # Write the strings.xml output file
    #
    # @param [Hash] terms
    #        The json parsed terms exported by POEditor and sorted alphabetically
    # @param [String] file
    #        The path to the file to write the content to
    # @param [Hash<String,String>] substitutions
    #        The list of substitutions to apply to the translations
    # @param [Bool] print_date
    #        Should we print the date in the header of the generated file
    # @param [Regexp] exclude
    #        A regular expression to filter out terms.
    #        Terms matching this Regexp will be ignored and won't be part of the generated file
    #
    def self.write_strings_xml(terms, file, substitutions: nil, print_date: false, exclude: Poesie::Filters::EXCLUDE_IOS)
      stats = { :excluded => 0, :nil => [], :count => 0 }

      Log::info(" - Save to file: #{file}")
      File.open(file, "w") do |fh|
        xml_builder = Builder::XmlMarkup.new(:target => fh, :indent => 4)
        xml_builder.instruct!
        xml_builder.comment!("Exported from POEditor   ")
        xml_builder.comment!(Time.now) if print_date
        xml_builder.comment!("see https://poeditor.com ")
        xml_builder.resources do |resources_node|
          terms.each do |term|
            (term, definition, plurals, comment, context) = ['term', 'definition', 'term_plural', 'comment', 'context'].map { |k| term[k] }
            
            # Filter terms and update stats
            next if (term.nil? || term.empty? || definition.nil?) && stats[:nil] << term
            next if (term =~ exclude) && stats[:excluded] += 1
            stats[:count] += 1

            # Terms with dots are invalid in Android ("R.string.foo.bar" won't work), so replace dots with underscores
            term.gsub!('.', '_')
            plurals.gsub!('.', '_')

            xml_builder.comment!(context) unless context.empty?
            if plurals.empty?
              definition = Poesie::process(definition, substitutions).gsub('"', '\\"')
              resources_node.string("\"#{definition}\"", :name => term)
            else
              resources_node.plurals(:name => plurals) do |plurals_node|
                definition.each do |plural_quantity, plural_value|
                  plural_value = Poesie::process(plural_value, substitutions).gsub('"', '\\"')
                  plurals_node.item("\"#{plural_value}\"", :quantity => plural_quantity)
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
