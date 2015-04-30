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
      @transform_to   = options[:transform_to]   || {}
      @transform_from = options[:transform_from] || {}
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
    # @param  shortcode [String] job shortcode to select candidates from
    # @param  options   [Hash]   extra options like `stage_slug` or `limit`
    # @option options :stage [String]        optional stage slug, if not given candidates are listed for all stages
    # @option options :limit [Number|String] optional limit of candidates to download, if not given all candidates are listed
    def job_candidates(shortcode, options = {})
      url = build_job_candidates_url(shortcode, options)
      transform_to(:candidate, get_request(url)['candidates'])
    end

    # list of questions for job
    # @param shortcode [String] job short code
    def job_questions(shortcode)
      transform_to(:question, get_request("jobs/#{shortcode}/questions")['questions'])
    end

    # create new candidate for given job
    # @param candidate  [Hash] the candidate data as described in
    #    http://resources.workable.com/add-candidates-using-api
    #    including the `{"candidate"=>{}}` part
    # @param shortcode  [String] job short code
    # @param stage_slug [String] optional stage slug
    # @return [Hash] the candidate information without `{"candidate"=>{}}` part
    def create_job_candidate(candidate, shortcode, stage_slug = nil)
      shortcode = "#{shortcode}/#{stage_slug}" unless stage_slug.nil?
      transform_to(:candidate, post_request("jobs/#{shortcode}/candidates", candidate)["candidate"])
    end

    # list of stages defined for company
    def stages
      transform_to(:stage, get_request("stages")['stages'])
    end

    # list of external recruiters for company
    def recruiters
      transform_to(:stage, get_request("recruiters")['recruiters'])
    end

    private

    attr_reader :api_key, :subdomain

    # build the url to api
    def api_url
      "https://www.workable.com/spi/v%s/accounts/%s" % [Workable::API_VERSION, subdomain]
    end

    # do the get request to api
    def get_request(url)
      do_request(url, Net::HTTP::Get)
    end

    # do the post request to api
    def post_request(url, data)
      do_request(url, Net::HTTP::Post) do |request|
        request.body = transform_from(:candidate, data).to_json
      end
    end

    # generic part of requesting api
    def do_request(url, type, &block)
      uri = URI.parse("#{api_url}/#{url}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request  = type.new(uri.request_uri, headers)
      yield request if block_given?
      response = http.request(request)

      parse!(response)
    end

    # parse the api response
    def parse!(response)
      case response.code.to_i
      when 204, 205  # handled no response
        nil
      when 200...300 # handled with response
        JSON.parse(response.body)
      when 401
        raise Errors::NotAuthorized, JSON.parse(response.body)["error"]
      when 404
        raise Errors::NotFound, JSON.parse(response.body)["error"]
      when 422
        handle_response_422(response)
      when 503
        raise Errors::RequestToLong, response.body
      else
        raise Errors::InvalidResponse, "Response code: #{response.code} message: #{response.body}"
      end
    end

    def handle_response_422(response)
      data = JSON.parse(response.body)
      if
        data["validation_errors"] &&
        data["validation_errors"]["email"] &&
        data["validation_errors"]["email"].include?("candidate already exists")
      then
        raise Errors::AlreadyExists, data["error"]
      else
        raise Errors::NotFound, data["error"]
      end
    end

    # default headers for authentication and JSON support
    def headers
      {
        'Accept'        => 'application/json',
        'Authorization' => "Bearer #{api_key}",
        'Content-Type'  => 'application/json',
        'User-Agent'    => 'Workable Ruby Client',
      }
    end

    # build url for fetching job candidates
    # @param  shortcode [String] job shortcode to select candidates from
    # @param  options   [Hash]   extra options like `stage_slug` or `limit`
    # @option options :stage_slug [String]        optional stage slug, if not given candidates are listed for all stages
    # @option options :limit      [Number|String] optional limit of candidates to download, if not given all candidates are listed
    def build_job_candidates_url(shortcode, options)
      if (stage_slug = options.delete(:stage))
      then stage_slug = "/#{stage_slug}"
      end
      params =
      if options.empty?
      then ""
      else "?#{options.map{|k,v| "#{k}=#{v}"}.join("&")}"
      end
      "jobs/#{shortcode}#{stage_slug}/candidates#{params}"
    end

    # transform result using given method if defined
    # @param type [Symbol] type of the transformation, one of `[:job, :candidate, :question, :stage]`
    # @param result [Hash|Array|nil] the value to transform, can be nothing, `Hash` of values or `Array` of `Hash`es
    # @return transformed result if transformation exists for type, raw result otherwise
    def transform_to(type, result)
      transform(@transform_to[type], result)
    end

    # transform input using given method if defined
    # @param type [Symbol] type of the transformation, only `[:candidate]` supported so far
    # @param result [Hash|Array|nil] the value to transform, can be nothing, `Hash` of values or `Array` of `Hash`es
    # @return transformed input if transformation exists for type, raw input otherwise
    def transform_from(type, input)
      transform(@transform_from[type], input)
    end

    # selects transformation strategy based on the inputs
    # @param transformation [Method|Proc|nil] the transformation to perform
    # @param data           [Hash|Array|nil]  the data to transform
    # @return               [Object|nil]
    #    results of the transformation if given, raw data otherwise
    def transform(transformation, data)
      return data unless transformation
      case data
      when nil
        data
      when Array
        data.map{|datas| transformation.call(datas) }
      else
        transformation.call(data)
      end
    end

  end
end
