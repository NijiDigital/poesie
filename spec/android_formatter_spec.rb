require 'spec_helper'

describe Poesie::AndroidFormatter do
  before do
    Poesie::Log::quiet = true
  end

  let(:terms) do
    JSON.parse(fixture('terms.json'))
    end

  it "generates proper strings.xml file" do
    Dir.mktmpdir do |dir|
      path = dir + '/strings.xml'
      Poesie::AndroidFormatter::write_strings_xml(terms, path)
      expect(File.exist?(path)).to eq(true)
      expect(File.read(path)).to eq(fixture('strings.xml'))
    end
  end

  it "generates proper strings.xml file with date" do
    Dir.mktmpdir do |dir|
      path = dir + '/strings.xml'
      stub_time()
      Poesie::AndroidFormatter::write_strings_xml(terms, path, print_date: true)
      expect(File.exist?(path)).to eq(true)
      expect(File.read(path)).to eq(fixture('strings-date.xml'))
    end
  end

  it "generates proper strings.xml file with substitutions" do
    Dir.mktmpdir do |dir|
      path = dir + '/strings.xml'
      repl = [{ "avez" => "possédez" }, { "o" => "0" }, { "/^\s+/" => "", "/\s+$/" => "" }]
      Poesie::AndroidFormatter::write_strings_xml(terms, path, substitutions: repl)
      expect(File.exist?(path)).to eq(true)
      expect(File.read(path)).to eq(fixture('strings-replaced.xml'))
    end
  end
end
