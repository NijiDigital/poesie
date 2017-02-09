require 'spec_helper'

describe Poesie::AppleFormatter do
  before do
    Poesie::Log::quiet = true
  end

  let(:terms) do
    JSON.parse(fixture('terms.json'))
    end

    describe "Localizable.strings" do
    it "generates proper strings file" do
      Dir.mktmpdir do |dir|
        path = dir + '/Localizable.strings'
        Poesie::AppleFormatter::write_strings_file(terms, path)
        expect(File.exist?(path)).to eq(true)
        expect(File.read(path)).to eq(fixture('Localizable.strings'))
      end
    end

    it "generates proper strings file with date" do
      Dir.mktmpdir do |dir|
        path = dir + '/Localizable.strings'
        stub_time()
        Poesie::AppleFormatter::write_strings_file(terms, path, print_date: true)
        expect(File.exist?(path)).to eq(true)
        expect(File.read(path)).to eq(fixture('Localizable-date.strings'))
      end
    end


    it "generates proper strings file with substitutions" do
      Dir.mktmpdir do |dir|
        path = dir + '/Localizable.strings'
        repl = [{ "avez" => "possédez" }, { "o" => "0" }, { "/^\s+/" => "", "/\s+$/" => "" }]
        Poesie::AppleFormatter::write_strings_file(terms, path, substitutions: repl)
        expect(File.exist?(path)).to eq(true)
        expect(File.read(path)).to eq(fixture('Localizable-replaced.strings'))
      end
    end
  end

  describe "Localizable.stringsdict" do
    it "generates proper stringsdict file" do
      Dir.mktmpdir do |dir|
        path = dir + '/Localizable.stringsdict'
        Poesie::AppleFormatter::write_stringsdict_file(terms, path)
        expect(File.exist?(path)).to eq(true)
        expect(File.read(path)).to eq(fixture('Localizable.stringsdict'))
      end
    end

    it "generates proper stringsdict file with date" do
      Dir.mktmpdir do |dir|
        path = dir + '/Localizable.stringsdict'
        stub_time()
        Poesie::AppleFormatter::write_stringsdict_file(terms, path, print_date: true)
        expect(File.exist?(path)).to eq(true)
        expect(File.read(path)).to eq(fixture('Localizable-date.stringsdict'))
      end
    end

    it "generates proper stringsdict file with substitutions" do
      Dir.mktmpdir do |dir|
        path = dir + '/Localizable.stringsdict'
        repl = [{ "avez" => "possédez" }, { "o" => "0" }, { "/^\s+/" => "", "/\s+$/" => "" }]
        Poesie::AppleFormatter::write_stringsdict_file(terms, path, substitutions: repl)
        expect(File.exist?(path)).to eq(true)
        expect(File.read(path)).to eq(fixture('Localizable-replaced.stringsdict'))
      end
    end
  end

end
