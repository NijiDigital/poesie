require 'spec_helper'

describe "AppleExporter" do
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
			POEditor::AndroidFormatter::write_strings_xml(terms, path)
			expect(File.exist?(path)).to eq(true)
			expect(File.read(path)).to eq(fixture('strings.xml'))
		end
	end

end
