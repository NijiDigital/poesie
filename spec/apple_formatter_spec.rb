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

	it "generates proper strings file with replacements" do
		Dir.mktmpdir do |dir|
			path = dir + '/Localizable.strings'
			replacements = { "o" => "0", "avez" => "possédez" }
			stub_time()
			Poesie::AppleFormatter::write_strings_file(terms, path, replacements)
			expect(File.exist?(path)).to eq(true)
			expect(File.read(path)).to eq(fixture('Localizable-replaced.strings'))
		end
	end

	it "generates proper stringsdict filewith replacements" do
		Dir.mktmpdir do |dir|
			path = dir + '/Localizable2.stringsdict'
			replacements = { "o" => "0", "avez" => "possédez" }
			Poesie::AppleFormatter::write_stringsdict_file(terms, path, replacements)
			expect(File.exist?(path)).to eq(true)
			expect(File.read(path)).to eq(fixture('Localizable-replaced.stringsdict'))
		end
	end
end
