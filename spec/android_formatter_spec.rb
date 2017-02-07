require 'spec_helper'

describe Poesie::AndroidFormatter do
	before do
		Log::quiet = true
	end

	let(:terms) do
		JSON.parse(fixture('terms.json'))
    end

	it "generates proper strings.xml file" do
		Dir.mktmpdir do |dir|
			path = dir + '/Localizable.strings'
			stub_time()
			Poesie::AndroidFormatter::write_strings_xml(terms, path)
			expect(File.exist?(path)).to eq(true)
			expect(File.read(path)).to eq(fixture('strings.xml'))
		end
	end

	it "generates proper strings.xml file with replacements" do
		Dir.mktmpdir do |dir|
			path = dir + '/Localizable.strings'
			replacements = { "o" => "0", "avez" => "possédez" }
			stub_time()
			Poesie::AndroidFormatter::write_strings_xml(terms, path, replacements)
			expect(File.exist?(path)).to eq(true)
			expect(File.read(path)).to eq(fixture('strings-replaced.xml'))
		end
	end
end
