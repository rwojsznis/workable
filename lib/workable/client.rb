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

    def job_candidates(shortcode)
      get_request("jobs/#{shortcode}/candidates")['candidates']
    end

    private

    attr_reader :api_key, :subdomain

    def api_url
      "https://www.workable.com/spi/v%s/accounts/%s" % [Workable::API_VERSION, subdomain]
    end

    def get_request(url)
      uri = URI.parse("#{api_url}/#{url}")

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request  = Net::HTTP::Get.new(uri.request_uri, headers)
      response = http.request(request)

      validate!(response)

      JSON.parse(response.body)
    end

    def validate!(response)
      case response.code.to_i
      when 401
        raise Errors::NotAuthorized, response.body
      when 404
        raise Errors::NotFound, response.body
      when proc { |code| code != 200 }
        raise Errors::InvalidResponse, "Response code: #{response.code}"
      end
    end

    def headers
      {
        'Accept' => 'application/json',
        'Authorization' => "Bearer #{api_key}",
        'User-Agent' => 'Workable Ruby Client'
      }
    end
  end
end
