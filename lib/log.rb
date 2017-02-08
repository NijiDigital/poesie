module Poesie
  module Log
    @@quiet = false
    def self.quiet=(value)
      @@quiet = value
    end

    def self.title(str) # bg yellow
      puts "\e[44;37m#{str}\e[0m" unless @@quiet
    end

    def self.error(str)
      puts "\e[1;31m! #{str}\e[0m" unless @@quiet
    end

    def self.info(str)
      puts "\e[1;32m√ #{str}\e[0m" unless @@quiet
    end

    def self.subtitle(str)
      puts "\e[1;33m√ #{str}\e[0m" unless @@quiet
    end
  end
end
