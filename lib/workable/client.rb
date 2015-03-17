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

    def job_candidates(shortcode, stage_slug = nil)
      shortcode = "#{shortcode}/#{stage_slug}" unless stage_slug.nil?
      get_request("jobs/#{shortcode}/candidates")['candidates']
    end

    def job_questions(shortcode)
      get_request("jobs/#{shortcode}/questions")['questions']
    end

    def stages
      get_request("stages")['stages']
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
      when 503
        raise Errors::RequestToLong, response.body
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
