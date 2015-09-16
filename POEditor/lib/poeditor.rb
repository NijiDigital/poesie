require File.expand_path('utils/log', File.dirname(__FILE__))

require 'net/http'
require 'json'

module POEditor
  VERSION = '0.1.0'
  API_TOKEN = 'fc1881292605d21bc5531c6ffcf3e410'

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

    # @param [String] format          The format to export to, like 'apple_strings' or 'android_strings'
    # @return [Hash<String,String>]   The list of languages to export and associated files to save the result to
    def run(format, langs)
      langs.each do |lang, file|
        Log::info("Language: #{lang}")
        Log::info(' - Generating export...')
        uri = generate_export_uri(format, lang)
        Log::info(' - Downloading exported file...')
        content = Net::HTTP.get(URI(uri))
        if block_given?
          Log::info(' - Processing generated strings...')
          content = yield content
        end
        Log::info(" - Save to file: #{file}")
        File.write(file, content)
      end
    end

    private

    # @param [String] format   The format to export to, like 'apple_strings' or 'android_strings'
    # @param [String] lang     Language code, like 'fr', 'en', etc
    # @return [String]         URL of the exported file ready to be downloaded
    def generate_export_uri(format, lang)
      uri = URI('https://poeditor.com/api/')
      res = Net::HTTP.post_form(uri, 'api_token' => @api_token, 'action' => 'export', 'id' => @project_id, 'type' => format, 'language' => lang)
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
    def self.format
      'apple_strings'
    end

    # @param [String] strings_content   The content of the Localizable.strings file as exported by POEditor
    # @return [String]                  The reformatted content, sorted, grouped with 'MARK's and annotated
    def self.process_content(strings_content)
      lines = strings_content.split("\n").reject do |line|
        line =~ %r(/\*.*\*/) || line =~ %r(^$) || line =~ %r(".*_android") # Remove comments, empty lines, and android-specific strings
      end.sort
      last_prefix = ''
      out_lines = ['/'+'*'*79, ' * Exported from POEditor - https://poeditor.com', " * #{Time.now}", ' '+'*'*78+'*'+'/', '']
      lines.each do |line|
        prefix = %r("([^_]*)_.*").match(line)
        if prefix && prefix[1] != last_prefix
          last_prefix = prefix[1]
          mark = last_prefix[0].upcase + last_prefix[1..-1].downcase
          out_lines += ['', '/'*80, "// MARK: #{mark}"]
        end
        out_lines += [line.gsub('\\\\n', '\\n')]
      end
      return out_lines.join("\n") + "\n"
    end
  end

  module AndroidFormatter
    ANDROID_MATCHER = /(?:^|\s*)<string\s*name="(.*)">\s*"(.*)"\s*<\/string>(?:$|\s*)/
    ANDROID_MATCHER_PLURALS_START = /(?:^|\s*)<plurals\s*name="(.*)">(?:$|\s*)/
    ANDROID_MATCHER_ITEM = /(?:^|\s*)<item\s*quantity="(.*)">\s*(.*)\s*<\/item>(?:$|\s*)/
    ANDROID_MATCHER_PLURALS_END = /(?:^|\s*)<\/plurals>(?:$|\s*)/

    def self.format
      'android_strings'
    end

    def self.strings(strings_content)
      suffixes = %w(ios ios(+))
      strings = Hash.new
      strings_content.split("\n").each do |line|
        if line.match(ANDROID_MATCHER)
          key = $1.to_sym
          value = $2
          strings[key] = value unless key.to_s.end_with?(*suffixes)
        end
      end
      strings
    end

    def self.plurals(strings_content)
      plurals = String.new
      strings_content.split("\n").each do |line|
        case line
          when ANDROID_MATCHER_PLURALS_START
            plurals << "    #{line}\n"
          when ANDROID_MATCHER_ITEM
            plurals << "        #{line}\n"
          when ANDROID_MATCHER_PLURALS_END
            plurals << "    #{line}\n"
          else
            ''
        end
      end
      plurals
    end

    # @param [String] strings_content   The content of the strings.xml file as exported by POEditor
    # @return [String]                  The reformatted content
    def self.process_content(strings_content)
      strings = strings(strings_content)
      content = String.new
      content << "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
      content << "<!-- Exported from POEditor\n"
      content << "     #{Time.now}\n"
      content << "     see https://poeditor.com -->\n"
      content << "<resources>\n"
      strings.sort.each { |key, value|
        content << "    <string name=\"#{key}\">\"#{value}\"</string>\n"
      }
      content << plurals(strings_content)
      content << "</resources>\n"
    end
  end

end
