require 'spec_helper'

describe Poesie::ContextFormatter do
  before do
    Poesie::Log::quiet = true
  end

  let(:terms) do
    JSON.parse(fixture('terms.json'))
  end

  describe "Context.json" do
    it "generates proper context json file" do
      Dir.mktmpdir do |dir|
        path = dir + '/Context.json'
        stub_time()
        Poesie::ContextFormatter::write_context_json(terms, path)
        expect(File.exist?(path)).to eq(true)
        expect(File.read(path)).to eq(fixture('Context.json'))
      end
    end

    it "generates proper context json file, filtering keys" do
      Dir.mktmpdir do |dir|
        path = dir + '/Context.json'
        stub_time()
        Poesie::ContextFormatter::write_context_json(terms, path, exclude: /_(ios|android)$/)
        expect(File.exist?(path)).to eq(true)
        expect(File.read(path)).to eq(fixture('Context-filtered.json'))
      end
    end
  end
end
