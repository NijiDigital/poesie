module Log

  def self.title(str) # bg yellow
    puts "\e[44;37m#{str}\e[0m"
  end

  def self.error(str)
    puts "\e[1;31m! #{str}\e[0m"
  end

  def self.info(str)
    puts "\e[1;32m√ #{str}\e[0m"
  end

end
