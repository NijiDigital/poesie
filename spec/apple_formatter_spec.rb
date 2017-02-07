require 'spec_helper'

describe Poesie::AppleFormatter do
	before do
		Log::quiet = true
	end

	let(:terms) do
		JSON.parse(fixture('terms.json'))
    end

	it "generates proper strings file" do
		Dir.mktmpdir do |dir|
			path = dir + '/Localizable.strings'
			stub_time()
			Poesie::AppleFormatter::write_strings_file(terms, path)
			expect(File.exist?(path)).to eq(true)
			expect(File.read(path)).to eq(fixture('Localizable.strings'))
		end
	end

	it "generates proper stringsdict file" do
		Dir.mktmpdir do |dir|
			path = dir + '/Localizable.stringsdict'
			Poesie::AppleFormatter::write_stringsdict_file(terms, path)
			expect(File.exist?(path)).to eq(true)
			expect(File.read(path)).to eq(fixture('Localizable.stringsdict'))
		end
	end

	it "generates proper context json file" do
		Dir.mktmpdir do |dir|
			path = dir + '/Context.json'
			stub_time()
			Poesie::AppleFormatter::write_context_json(terms, path)
			expect(File.exist?(path)).to eq(true)
			expect(File.read(path)).to eq(fixture('Context.json'))
		end
	end
end
