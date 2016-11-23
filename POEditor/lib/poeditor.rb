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
      content = self.process_content(terms, filter)
      Log::info(" - Save to file: #{file}")
      File.write(file, content)
    end

    def self.write_context(terms, file, filter)
      error_content = self.process_context(terms, file, filter)
      Log::info(" - Save to file: #{file}")
      File.write(file, error_content)
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
        (key, value, comment, context) = ['term', 'definition', 'comment', 'context'].map { |k| term[k] }

        # Skip ugly cases if POEditor is buggy for some entries
        if key.nil? || key.empty? || value.nil?; filteredKeys["nil"] += 1; next; end
        # Remove android-specific strings
        if key =~ /_android$/; filteredKeys["android"] += 1; next; end
        # Filter
        if (filter && (key.include? filter)); filteredKeys["filter"] += 1; next; end

        # Generate MARK from prefixes
        prefix = %r(([^_]*)_.*).match(key)
        if prefix && prefix[1] != last_prefix
          last_prefix = prefix[1]
          mark = last_prefix[0].upcase + last_prefix[1..-1].downcase
          out_lines += ['', '/'*80, "// MARK: #{mark}"]
        end
        # Escape some chars
        if value.is_a? Hash
          value = value["one"]
        end
      #  puts("#{key} : #{value}")

        value = value
                    .gsub("\u2028", '') # Sometimes inserted by the POEditor exporter
                    .gsub("\n", "\\n") # Replace actual CRLF with '\n'
                    .gsub('"', '\\"') # Escape quotes
                    .gsub(/%(\d+\$)?s/, '%\1@') # replace %s with %@ for iOS
        out_lines << %Q(// CONTEXT: #{context.gsub("\n", '\n')}) unless context.empty?
        out_lines << %Q("#{key}" = "#{value}";)
      end

      Log::error("Filtered by:\n Filter: #{filteredKeys["filter"]}, Android: #{filteredKeys["android"]}, Nil: #{filteredKeys["nil"]}")
      return out_lines.join("\n") + "\n"
    end

    ##
    ## Context
    ##
    # @param [Hash] terms   The json parsed terms exported by POEditor and sorted alphabetically
    # @return [String]                  The reformatted content, sorted, grouped with 'MARK's and annotated
    def self.process_context(terms, file, filter)
      out_lines = ['/'+'*'*79, ' * Exported from POEditor - https://poeditor.com', " * #{Time.now}", ' '+'*'*78+'*'+'/', '']
      out_lines += ["enum #{File.basename(file, '.swift')}: String, ErrorType {\n"]
      last_prefix = ''
      filteredKeys = {"filter" => 0, "android" => 0, "nil" => 0}

      #switch on key / context
      terms.each do |term|
        (key, value, comment, context) = ['term', 'definition', 'comment', 'context'].map { |k| term[k] }

        # Skip ugly cases if POEditor is buggy for some entries
        if key.nil? || key.empty? || value.nil? || context.nil?; filteredKeys["nil"] += 1; next; end
        # Remove android-specific strings
        if key =~ /_android$/; filteredKeys["android"] += 1; next; end
        # Filter by --Filter options
        if (filter && !(key.include? filter)); filteredKeys["filter"] += 1; next; end

        # Generate MARK from prefixes
        prefix = %r(([^_]*)_.*).match(key)
        if prefix && prefix[1] != last_prefix
          last_prefix = prefix[1]
          mark = last_prefix[0].upcase + last_prefix[1..-1].downcase
          out_lines += ['', '/'*80, "// MARK: #{mark}"]
        end
        # Escape some chars
        context = context
                    .gsub("\u2028", '') # Sometimes inserted by the POEditor exporter
                    .gsub("\\", "\\\\\\") # Replace actual \ with \\
                    .gsub('\\\\"', '\\"') # Replace actual \\" with \"
                    .gsub(/%(\d+\$)?s/, '%\1@') # replace %s with %@ for iOS
        out_lines << %Q(    case #{key.camel_case} = "#{context}";)
      end

      out_lines += ["}\n"]
      out_lines += ["extension #{File.basename(file, '.swift')} {\n"]
      out_lines += ['  var localizedMessage: String {']
      out_lines += ['    switch self {']

      #switch on key / value
      terms.each do |term|
        (key, value, comment, context) = ['term', 'definition', 'comment', 'context'].map { |k| term[k] }

        # Skip ugly cases if POEditor is buggy for some entries
        if key.nil? || key.empty? || value.nil? || context.nil?; filteredKeys["nil"] += 1; next; end
        # Remove android-specific strings
        if key =~ /_android$/; filteredKeys["android"] += 1; next; end
        # Filter by --Filter options
        if (filter && !(key.include? filter)); filteredKeys["filter"] += 1; next; end

        # Generate MARK from prefixes
        prefix = %r(([^_]*)_.*).match(key)
        if prefix && prefix[1] != last_prefix
          last_prefix = prefix[1]
          mark = last_prefix[0].upcase + last_prefix[1..-1].downcase
          out_lines += ['', '/'*80, "// MARK: #{mark}"]
        end
        # Escape some chars
        value = value
                    .gsub("\u2028", '') # Sometimes inserted by the POEditor exporter
                    .gsub("\n", "\\n") # Replace actual CRLF with '\n'
                    .gsub('"', '\\"') # Escape quotes
                    .gsub(/%(\d+\$)?s/, '%\1@') # replace %s with %@ for iOS

        out_lines += ["    case .#{key.camel_case}:"]
        out_lines += ["      return \"#{value}\""]
      end

      out_lines += ['    }']
      out_lines += ['  }']
      out_lines += ['}']

      Log::error("Filtered by:\n Filter: #{filteredKeys["filter"]/2}, Android: #{filteredKeys["android"]/2}, Nil: #{filteredKeys["nil"]/2}")
      return out_lines.join("\n") + "\n"

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
          (key, value, plurals, comment, context) = ['term', 'definition', 'term_plural', 'comment', 'context'].map { |k| term[k] }
          # Skip ugly cases if POEditor is buggy for some entries
          next if key.nil? || key.empty? || value.nil?
          next if key =~ /_ios$/
          xml_builder.comment!(context) unless context.empty?
          if plurals.empty?
            value = value.gsub('"', '\\"')
            resources.string("\"#{value}\"", :name => key)
          else
            resources.plurals(:name => plurals) {
                |plural|
              value.each do |plural_quantity, plural_value|
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
