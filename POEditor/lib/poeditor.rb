require File.expand_path('poeditor/utils/log', File.dirname(__FILE__))
require File.expand_path('poeditor/utils/file_poeditor', File.dirname(__FILE__))
require File.expand_path('poeditor/apple/cleaner', File.dirname(__FILE__))
require File.expand_path('poeditor/android/cleaner', File.dirname(__FILE__))

module POEditor
  VERSION = '0.0.1'

  def self.exit_with_error(message)
    Log::error message
    exit 1
  end

end
