class File

  def self.find_apple_file(dir)
    find_file(dir, 'strings')
  end

  def self.find_android_file(dir)
    find_file(dir, 'xml')
  end

  def self.keys_and_values(file_name, matcher)
    wordings = Hash.new
    if File.exist?(file_name)
      File.open(file_name).each_line do |line|
        if line.match(matcher)
          k = $1.to_sym
          v = $2.to_s.gsub("\\\\n", "\\n")
          wordings[k] = v
        end
      end
    end
    wordings
  end

  private

  def self.find_file(dir, ext)
    Dir.chdir(dir) do
      files = Dir.glob("*.#{ext}")
      files.first.nil? ? nil : File.expand_path(files.first, dir)
    end
  end

end
