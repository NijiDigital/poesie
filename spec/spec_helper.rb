require 'poesie'
require 'tmpdir'

def fixture(name)
  File.read(File.expand_path("fixtures/#{name}", File.dirname(__FILE__)))
end

def stub_time()
  allow(Time).to receive(:now).and_return('<<<STUBBED_DATE_TIME>>>')
end
