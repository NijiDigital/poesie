require File.expand_path('../utils/file_poeditor', File.dirname(__FILE__))

module POEditor
  module Android

    class Cleaner

      ANDROID_MATCHER = /(?:^|\s*)<string\s*name="(.*)">\s*(.*)\s*<\/string>(?:$|\s*)/
      ANDROID_MATCHER_PLURALS_START = /(?:^|\s*)<plurals\s*name="(.*)">(?:$|\s*)/
      ANDROID_MATCHER_ITEM = /(?:^|\s*)<item\s*quantity="(.*)">\s*(.*)\s*<\/item>(?:$|\s*)/
      ANDROID_MATCHER_PLURALS_END = /(?:^|\s*)<\/plurals>(?:$|\s*)/

      def initialize(poeditor_file, android_file)
        puts "\n"
        Log::title('Android')
        basename = File.basename(android_file)
        Log::success("Generating strings in #{basename}...\n")
        clean(poeditor_file, android_file)
      end

      private

      def clean(poeditor_file, android_file)
        suffixes = %w(ios ios(+))
        wordings = clean_poeditor_file(poeditor_file, ANDROID_MATCHER, suffixes)
        print_android_file(wordings.sort, poeditor_file, android_file)
      end

      def clean_poeditor_file(poeditor_file, matcher, suffixes)
        wordings = File.keys_and_values(poeditor_file, matcher)
        wordings.each { |key, _|
          wordings.delete(key) if key.to_s.end_with?(*suffixes)
        }
      end

      def print_android_file(hash, poeditor_file, file)
        File.open(file, 'w') { |f|
          f.write '<?xml version="1.0" encoding="utf-8"?>'
          f.write "<resources>\n\n"
          hash.each { |key, value|
            v = value.gsub(" '", " \\\\'")
            f.write "    <string name=\"#{key}\">#{v}</string>\n"
          }
          print_plurals(poeditor_file, f) unless poeditor_file.nil?
          f.write "\n</resources>\n"
        }
      end

      def print_plurals(poeditor_file, file)
        if File.exist?(poeditor_file)
          File.open(poeditor_file).each_line do |line|
            case line
              when ANDROID_MATCHER_PLURALS_START
                file.write "    #{line}"
              when ANDROID_MATCHER_ITEM
                file.write "        #{line}"
              when ANDROID_MATCHER_PLURALS_END
                file.write "    #{line}"
              else
                ''
            end
          end
        end
      end

    end

  end
end
