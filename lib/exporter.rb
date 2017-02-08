require 'net/http'

module Poesie
  class Exporter
    # @param [String] api_token
    #        POEditor API Token
    # @param [String] project_id
    #        ID of the project in your POEditor Dashboard
    #
    def initialize(api_token, project_id)
      @api_token = api_token
      @project_id = project_id
    end

    # Use the POEditor API to download the terms for a given language, then call a block
    # to post-process those terms (exported as a JSON structure)
    #
    # @param [String] lang
    #        The language to export
    # @block [[JSON] -> Void]
    #        The action to do with the exported terms
    #        Typically call one of AppleFormatter::… or AndroidFormatter::… methods here
    #
    def run(lang)
        Log::info(' - Generating export...')
        uri = generate_export_uri(lang)
        Log::info(' - Downloading exported file...')
        json_string = Net::HTTP.get(URI(uri))
        json = JSON.parse(json_string)
        terms = json.sort { |item1, item2| item1['term'] <=> item2['term'] }
        if block_given?
          Log::info(' - Processing generated strings...')
          yield terms
        end
    end

    private

    # @param [String] lang
    #        Language code, like 'fr', 'en', etc
    # @return [String] URL of the exported file ready to be downloaded
    #
    def generate_export_uri(lang)
      uri = URI('https://api.poeditor.com/v2/projects/export')
      res = Net::HTTP.post_form(uri, 'api_token' => @api_token, 'id' => @project_id, 'type' => 'json', 'language' => lang)
      json = JSON.parse(res.body)
      unless json['response']['status'] == 'success'
        r = json['response']
        puts "Error #{r['code']} (#{r['status']})\n#{r['message']}"
        exit 1
      end
      json['result']['url']
    end
  end
end
