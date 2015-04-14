module Workable
  class Client
    # set access to workable and data transformation methods
    #
    # @param options [Hash]
    # @option options :api_key   [String] api key for workable
    # @option options :subdomain [String] company subdomain in workable
    # @option options :transform_to [Hash<Symbol: Proc>] mapping of transformations for data
    #    available transformations: [:job, :candidate, :question, :stage]
    #    when no transformation is given raw Hash / Array data is returned
    #
    # @example transformation for candidates using `MyApp::Candidate.find_and_update_or_create`
    #    client = Workable::Client.new(
    #      api_key: 'api_key',
    #      subdomain: 'your_subdomain',
    #      transform_to: {
    #        candidate: &MyApp::Candidate.method(:find_and_update_or_create)
    #      }
    #    )
    #
    # @example Linkedin gem style with Mash
    #   require "hashie"
    #    client = Workable::Client.new(
    #      api_key: 'api_key',
    #      subdomain: 'your_subdomain',
    #      transform_to: {
    #        candidate: &Hashie::Mash.method(:new)
    #      }
    #    )
    def initialize(options = {})
      @api_key   = options.fetch(:api_key)   { fail Errors::InvalidConfiguration, "Missing api_key argument"   }
      @subdomain = options.fetch(:subdomain) { fail Errors::InvalidConfiguration, "Missing subdomain argument" }
      @transform_to = options[:transform_to] || {}
    end

    # request jobs of given type
    # @param type [String] type of jobs to fetch, `published` by default
    def jobs(type = 'published')
      transform_to(:job, get_request("jobs?phase=#{type}")['jobs'])
    end

    # request detailed information about job
    # @param shortcode [String] job short code
    def job_details(shortcode)
      transform_to(:job, get_request("jobs/#{shortcode}"))
    end

    # list candidates for given job
    # @param shortcode  [String]     job shortcode to select candidates from
    # @param stage_slug [String|nil] optional stage slug, if not given candidates are listed for all stages
    def job_candidates(shortcode, stage_slug = nil)
      shortcode = "#{shortcode}/#{stage_slug}" unless stage_slug.nil?
      transform_to(:candidate, get_request("jobs/#{shortcode}/candidates")['candidates'])
    end

    # list of questions for job
    # @param shortcode [String] job short code
    def job_questions(shortcode)
      transform_to(:question, get_request("jobs/#{shortcode}/questions")['questions'])
    end

    # list of stages defined for company
    def stages
      transform_to(:stage, get_request("stages")['stages'])
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

    # transform data using given method if defined
    # @param type [Symbol] type of the transformation, one of `[:job, :candidate, :question, :stage]`
    # @param result [Hash|Array|nil] the value to transform, can be nothing, `Hash` of values or `Array` of `Hash`es
    # @return transformed result if transformation exists for type, raw result otherwise
    def transform_to(type, result)
      return result unless @transform_to[type]
      case result
      when nil
        result
      when Array
        result.map{|values| @transform_to[type].call(values) }
      else
        @transform_to[type].call(result) if @transform_to[type]
      end
    end
  end
end
