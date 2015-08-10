require File.expand_path('../utils/file_poeditor', File.dirname(__FILE__))

module POEditor
  module Apple

    class Cleaner

      APPLE_MATCHER = /(?:^|\s*)"(.*)"\s*=\s*"(.*)"\s*(?:$|\s*)/

      def initialize(poeditor_file, apple_file)
        puts "\n"
        Log::title('Apple')
        basename = File.basename(apple_file)
        Log::success("Generating strings in #{basename}...\n")
        clean(poeditor_file, apple_file)
      end

      private

      def clean(poeditor_file, apple_file)
        suffixes = %w(android)
        wordings = clean_poeditor_file(poeditor_file, APPLE_MATCHER, suffixes)
        print_ios_file(wordings.sort, apple_file)
      end

      def clean_poeditor_file(poeditor_file, matcher, suffixes)
        wordings = File.keys_and_values(poeditor_file, matcher)
        wordings.each { |key, _|
          wordings.delete(key) if key.to_s.end_with?(*suffixes)
        }
      end

      def print_ios_file(hash, file)
        File.open(file, 'w+') { |f|
          hash.each { |key, value|
            v = value.gsub("\\'", "'")
            f.write "\"#{key}\" = \"#{v}\";\n"
          }
        }
      end

    end

  end
end
