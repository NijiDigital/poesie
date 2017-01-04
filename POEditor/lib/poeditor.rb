require File.expand_path('utils/log', File.dirname(__FILE__))
require File.expand_path('utils/string', File.dirname(__FILE__))

require 'net/http'
require 'json'
require 'builder'

module POEditor
  VERSION = '0.4.0'

  def self.exit_with_error(message)
    Log::error message
    exit 1
  end

  class Exporter
    # @param [String] api_token    POEditor API Token
    # @param [String] project_id   ID of the project in your POEditor Dashboard
    def initialize(api_token, project_id)
      @api_token = api_token
      @project_id = project_id
    end

    # @return [String]   The list of languages to export and associated files to save the result to
    def run(lang)
        Log::info(' - Generating export...')
        uri = generate_export_uri(lang)
        Log::info(' - Downloading exported file...')
        json_string = Net::HTTP.get(URI(uri))
        json = JSON.parse(json_string)
        terms = json.sort { |item1, item2| item1['term'] <=> item2['term'] }
        if block_given?
          Log::info(' - Processing generated strings...')
          yield terms
        end
    end

    private

    # @param [String] lang     Language code, like 'fr', 'en', etc
    # @return [String]         URL of the exported file ready to be downloaded
    def generate_export_uri(lang)
      uri = URI('https://poeditor.com/api/')
      res = Net::HTTP.post_form(uri, 'api_token' => @api_token, 'action' => 'export', 'id' => @project_id, 'type' => 'json', 'language' => lang)
      json = JSON.parse(res.body)
      if json['response']['status'] != 'success'
        r = json['response']
        puts "Error #{r['code']} (#{r['status']})\n#{r['message']}"
        exit 1
      else
        json['item']
      end
    end
  end

  module AppleFormatter

    def self.write_content(terms, file, filter)
      # File.open(file, "a+") { |out_file|
        content = self.process_content(terms, filter)
        # out_file.write(error_content)
      # }
      # content =
      Log::info(" - Save to file: #{file}")
      File.write(file, content)
    end

    # Write the JSON output file containing all context keys
    #
    # @param [Array<Hash<String, Any>>] terms
    #        JSON returned by the POEditor API
    # @param [String] file
    #        The path of the file to write
    # @param [String] filter
    #         Don't process keys containing this text
    #
    def self.write_context(terms, file, filter)

      context_hash = self.process_context(terms, filter)
      context_json = JSON.pretty_generate(context_hash)
      Log::info(" - Save to file: #{file}")
      File.open(file, "w") do |fh|
        fh.write(context_json)
      end

    end

    ##
    ## Content
    ##
    # @param [Hash] terms   The json parsed terms exported by POEditor and sorted alphabetically
    # @return [String]                  The reformatted content, sorted, grouped with 'MARK's and annotated
    def self.process_content(terms, filter)
      out_lines = ['/'+'*'*79, ' * Exported from POEditor - https://poeditor.com', " * #{Time.now}", ' '+'*'*79+'/', '']
      last_prefix = ''
      filteredKeys = {"filter" => 0, "android" => 0, "nil" => 0}

      terms.each do |term|
        (term, definition, comment, context) = ['term', 'definition', 'comment', 'context'].map { |k| term[k] }

        # Skip ugly cases if POEditor is buggy for some entries
        if term.nil? || term.empty? || definition.nil?; filteredKeys["nil"] += 1; next; end
        # Remove android-specific strings
        if term =~ /_android$/; filteredKeys["android"] += 1; next; end
        # Filter
        if (filter && (term.include? filter)); filteredKeys["filter"] += 1; next; end

        # Generate MARK from prefixes
        prefix = %r(([^_]*)_.*).match(term)
        if prefix && prefix[1] != last_prefix
          last_prefix = prefix[1]
          mark = last_prefix[0].upcase + last_prefix[1..-1].downcase
          out_lines += ['', '/'*80, "// MARK: #{mark}"]
        end
        # Escape some chars
        if definition.is_a? Hash
          definition = definition["one"]
        end
      #  puts("#{key} : #{value}")

        definition = definition
                    .gsub("\u2028", '') # Sometimes inserted by the POEditor exporter
                    .gsub("\n", "\\n") # Replace actual CRLF with '\n'
                    .gsub('"', '\\"') # Escape quotes
                    .gsub(/%(\d+\$)?s/, '%\1@') # replace %s with %@ for iOS
        out_lines << %Q(// CONTEXT: #{context.gsub("\n", '\n')}) unless context.empty?
        out_lines << %Q("#{term}" = "#{definition}";)
      end

      Log::error("Filtered by:\n Filter: #{filteredKeys["filter"]}, Android: #{filteredKeys["android"]}, Nil: #{filteredKeys["nil"]}")
      return out_lines.join("\n") + "\n"
    end

    ##
    ## Context
    ##
    # @param [Hash] terms   The json parsed terms exported by POEditor and sorted alphabetically
    # @return [String]                  The reformatted content, sorted, grouped with 'MARK's and annotated
    def self.process_context(terms, filter)

      # json_hash = Hash.new
      json_hash = { "date" => "#{Time.now}" }

      filteredKeys = {"filter" => 0, "android" => 0, "nil" => 0}

      #switch on term / context
      array_context = Array.new
      terms.each do |term|
        (term, definition, comment, context) = ['term', 'definition', 'comment', 'context'].map { |k| term[k] }

        # Skip ugly cases if POEditor is buggy for some entries
        if term.nil? || term.empty? || definition.nil? || context.nil?; filteredKeys["nil"] += 1; next; end
        # Remove android-specific strings
        if term =~ /_android$/; filteredKeys["android"] += 1; next; end
        # Filter by --Filter options
        if (filter && !(term.include? filter)); filteredKeys["filter"] += 1; next; end

        # Escape some chars
        context = context
                    .gsub("\u2028", '') # Sometimes inserted by the POEditor exporter
                    .gsub("\\", "\\\\\\") # Replace actual \ with \\
                    .gsub('\\\\"', '\\"') # Replace actual \\" with \"
                    .gsub(/%(\d+\$)?s/, '%\1@') # replace %s with %@ for iOS

        array_context << { "term" => "#{term.camel_case}", "context" => "#{context}" }

      end

      json_hash[:"contexts"] = array_context

      #switch on term / definition
      array_definition = Array.new
      terms.each_with_index do |term, index|
        (term, definition, comment, context) = ['term', 'definition', 'comment', 'context'].map { |k| term[k] }

        # Skip ugly cases if POEditor is buggy for some entries
        if term.nil? || term.empty? || definition.nil? || context.nil?; filteredKeys["nil"] += 1; next; end
        # Remove android-specific strings
        if term =~ /_android$/; filteredKeys["android"] += 1; next; end
        # Filter by --Filter options
        if (filter && !(term.include? filter)); filteredKeys["filter"] += 1; next; end

        # Escape some chars
        definition = definition
                    .gsub("\u2028", '') # Sometimes inserted by the POEditor exporter
                    .gsub("\n", "\\n") # Replace actual CRLF with '\n'
                    .gsub('"', '\\"') # Escape quotes
                    .gsub(/%(\d+\$)?s/, '%\1@') # replace %s with %@ for iOS

        array_definition << { "term" => "#{term.camel_case}", "definition" => "#{definition}" }

       end

       json_hash[:"definitions"] = array_definition
       Log::error("Filtered by:\n Filter: #{filteredKeys["filter"]/2}, Android: #{filteredKeys["android"]/2}, Nil: #{filteredKeys["nil"]/2}")
       return json_hash

    end

  end

  module AndroidFormatter

    # @param [Hash] terms   The json parsed terms exported by POEditor and sorted alphabetically
    # @return [String]                  The reformatted content
    def self.process_content(terms)
      xml_builder = Builder::XmlMarkup.new(:indent => 4)
      xml_builder.instruct!
      xml_builder.comment!("Exported from POEditor\n    #{Time.now}\n    see https://poeditor.com")
      xml_builder.resources {
          |resources|
        terms.each do |term|
          (term, definition, plurals, comment, context) = ['term', 'definition', 'term_plural', 'comment', 'context'].map { |k| term[k] }
          # Skip ugly cases if POEditor is buggy for some entries
          next if term.nil? || term.empty? || definition.nil?
          next if term =~ /_ios$/
          xml_builder.comment!(context) unless context.empty?
          if plurals.empty?
            definition = definition.gsub('"', '\\"')
            resources.string("\"#{definition}\"", :name => term)
          else
            resources.plurals(:name => plurals) {
                |plural|
              definition.each do |plural_quantity, plural_value|
                plural_value = plural_value.gsub('"', '\\"')
                plural.item("\"#{plural_value}\"", :quantity => plural_quantity)
              end
            }
          end
        end
      }
    end
  end
end
