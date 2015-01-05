module Workable
  class Client
    def initialize(options = {})
      @api_key   = options.fetch(:api_key)   { fail Errors::InvalidConfiguration, "Missing api_key argument"   }
      @subdomain = options.fetch(:subdomain) { fail Errors::InvalidConfiguration, "Missing subdomain argument" }
    end

    def jobs(type = 'published')
      get_request("jobs?phase=#{type}")['jobs'].map do |params|
        Job.new(params)
      end
    end

    def job_details(shortcode)
      Job.new(get_request"jobs/#{shortcode}")
    end

    private

    attr_reader :api_key, :subdomain

    def api_url
      'https://www.workable.com/spi/accounts/%s' % subdomain
    end

    def get_request(url)
      uri = URI.parse("#{api_url}/#{url}")

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request  = Net::HTTP::Get.new(uri.request_uri, headers)
      response = http.request(request)

      raise Errors::NotAuthorized, response.body if response.code.to_i == 401
      raise Errors::InvalidResponse, "Response code: #{response.code}" if response.code.to_i != 200

      JSON.parse(response.body)
    end

    def headers
      {
        'Authorization' => "Bearer #{api_key}",
        'User-Agent' => 'Workable Ruby Client'
      }
    end
  end
end
