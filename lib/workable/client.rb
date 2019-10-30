module Workable
  class Client
    # set access to workable and data transformation methods
    #
    # @param options [Hash]
    # @option options :api_key   [String] api key for workable
    # @option options :subdomain [String] company subdomain in workable
    # @option options :transform_to [Hash<Symbol: Proc>] mapping of transformations for data
    #    available transformations: [:job, :candidate, :question, :stage, :recruiter, :member]
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
      @api_key   = options.fetch(:api_key)   { configuration_error 'Missing api_key argument'   }
      @subdomain = options.fetch(:subdomain) { configuration_error 'Missing subdomain argument' }
      @transform_to   = Transformation.new(options[:transform_to])
      @transform_from = Transformation.new(options[:transform_from])
    end

    # return information about your account
    def about
      get_request('')
    end

    # returns a collection of your account members
    def members
      @transform_to.apply(:member, get_request('members')['members'])
    end

    # returns a collection of your account external recruiters
    def recruiters
      @transform_to.apply(:recruiter, get_request('recruiters')['recruiters'])
    end

    # returns a collection of your recruitment pipeline stages
    def stages
      @transform_to.apply(:stage, get_request('stages')['stages'])
    end

    # request posted jobs
    # @option params [Hash] optional filter parameters
    # @option params :state [String] Returns jobs with the current state. Possible values (draft, published, archived & closed)
    # @option params :limit [Integer] Specifies the number of jobs to try and retrieve per page
    # @option params :since_id [String] Returns results with an ID more than or equal to the specified ID.
    # @option params :max_id [String] Returns results with an ID less than or equal to the specified ID.
    # @option params :created_after [Timestamp|Integer] Returns results created after the specified timestamp.
    # @option params :updated_after [Timestamp|Integer] Returns results updated after the specified timestamp.
    def jobs(params = {})
      build_collection('jobs', :job, 'jobs', params)
    end

    # request detailed information about job
    # @param shortcode [String] job short code
    def job_details(shortcode)
      @transform_to.apply(:job, get_request("jobs/#{shortcode}"))
    end

    # list of questions for job
    # @param shortcode [String] job short code
    def job_questions(shortcode)
      @transform_to.apply(:question, get_request("jobs/#{shortcode}/questions")['questions'])
    end

    # application form questions for job
    # @param shortcode [String] job short code
    def job_application_form(shortcode)
      @transform_to.apply(:question, get_request("jobs/#{shortcode}/application_form"))
    end

    # return a collection of job's members
    # @param shortcode [String] job short code
    def job_members(shortcode)
      @transform_to.apply(:member, get_request("jobs/#{shortcode}/members")['members'])
    end

    # return a collection of the job's external recruiters
    # @param shortcode [String] job short code
    def job_recruiters(shortcode)
      @transform_to.apply(:recruiter, get_request("jobs/#{shortcode}/recruiters")['recruiters'])
    end

    # list candidates for given job
    # @param  shortcode [String] job shortcode to select candidates from
    # @param  params [Hash]   extra options like `state` or `limit`
    # @option params :state [String]        optional state slug, if not given candidates are listed for all stages
    # @option params :limit [Number|String] optional limit of candidates to download, if not given all candidates are listed
    # @option params :since_id [String] Returns results with an ID more than or equal to the specified ID.
    # @option params :max_id [String] Returns results with an ID less than or equal to the specified ID.
    # @option params :created_after [Timestamp|Integer] Returns results created after the specified timestamp.
    # @option params :updated_after [Timestamp|Integer] Returns results updated after the specified timestamp.
    def job_candidates(shortcode, params = {})
      build_collection("jobs/#{shortcode}/candidates", :candidate, 'candidates', params)
    end

    # return the full object of a specific candidate
    # @param shortcode [String] job shortcode to select candidate from
    # @param id [String] candidates's id
    def job_candidate(shortcode, id)
      @transform_to.apply(:candidate, get_request("jobs/#{shortcode}/candidates/#{id}")['candidate'])
    end

    # create new candidate for given job
    # @param candidate  [Hash] the candidate data as described in
    #    https://workable.readme.io/docs/job-candidates-create
    #    including the `{"candidate"=>{}}` part
    # @param shortcode  [String] job short code
    # @param stage_slug [String] optional stage slug
    # @return [Hash] the candidate information without `{"candidate"=>{}}` part
    def create_job_candidate(candidate, shortcode, stage_slug = nil)
      shortcode = "#{shortcode}/#{stage_slug}" if stage_slug

      response = post_request("jobs/#{shortcode}/candidates") do |request|
        request.body = @transform_from.apply(:candidate, candidate).to_json
      end

      @transform_to.apply(:candidate, response['candidate'])
    end

    def update_candidate(candidate_id, candidate)
      response = patch_request("candidates/#{candidate_id}") do |request|
        request.body = @transform_from.apply(:candidate, candidate).to_json
      end

      @transform_to.apply(:candidate, response['candidate'])
    end

    # list candidates
    # @param  params [Hash]   extra options like `state` or `limit`
    # @option params :state [String]        optional state slug, if not given candidates are listed for all stages
    # @option params :limit [Number|String] optional limit of candidates to download, if not given all candidates are listed
    # @option params :since_id [String] Returns results with an ID more than or equal to the specified ID.
    # @option params :max_id [String] Returns results with an ID less than or equal to the specified ID.
    # @option params :created_after [Timestamp|Integer] Returns results created after the specified timestamp.
    # @option params :updated_after [Timestamp|Integer] Returns results updated after the specified timestamp.
    def candidates(params = {})
      build_collection("candidates", :candidate, 'candidates', params)
    end

    # return the full object of a specific candidate
    # @param id [String] candidates's id
    def candidate(id)
      @transform_to.apply(:candidate, get_request("candidates/#{id}")['candidate'])
    end

    # list activities for given candidate
    # @param  id [String] candidate id to get activities from
    # @param  params [Hash]   extra options like `state` or `limit`
    # @option params :state [String]        optional state slug, if not given candidates are listed for all stages
    # @option params :limit [Number|String] optional limit of candidates to download, if not given all candidates are listed
    # @option params :since_id [String] Returns results with an ID more than or equal to the specified ID.
    # @option params :max_id [String] Returns results with an ID less than or equal to the specified ID.
    # @option params :created_after [Timestamp|Integer] Returns results created after the specified timestamp.
    # @option params :updated_after [Timestamp|Integer] Returns results updated after the specified timestamp.
    def candidate_activity(id, params = {})
      build_collection("candidates/#{id}/activities", :activity, 'activities', params)
    end

    # create a comment for given candidate
    # @param  candidate_id [String] candidate id to create a comment for
    # @param  member_id    [String] id of the member that created the comment
    # @param  comment_body [String] body of the comment that will be created
    def create_candidate_comment(candidate_id, member_id, comment_body)
      post_request("candidates/#{candidate_id}/comments") do |request|
        request.body = @transform_from.apply(:comment, {
          member_id: member_id,
          comment: {
            body: comment_body,
          }
        }).to_json
      end
    end

    def move(candidate_id, member_id, target_stage)
      post_request("candidates/#{candidate_id}/move") do |request|
        request.body = {
          member_id: member_id,
          target_stage: target_stage
        }.to_json
      end
    end

    private

    attr_reader :api_key, :subdomain

    # build the url to api
    def api_url
      @_api_url ||= 'https://%s.workable.com/spi/v%s/accounts/%s' % [subdomain, Workable::API_VERSION, subdomain]
    end

    # do the get request to api
    def get_request(url, params = {})
      params = URI.encode_www_form(params.keep_if { |k, v| k && v })
      full_url = params.empty? ? url : [url, params].join('?')
      do_request(full_url, Net::HTTP::Get)
    end

    # do the post request to api
    def post_request(url)
      do_request(url, Net::HTTP::Post) do |request|
        yield(request) if block_given?
      end
    end

    # do the post request to api
    def patch_request(url)
      do_request(url, Net::HTTP::Patch) do |request|
        yield(request) if block_given?
      end
    end

    # generic part of requesting api
    def do_request(url, type, &_block)
      uri = URI.parse("#{api_url}/#{url}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = type.new(uri.request_uri, headers)

      yield request if block_given?

      response = http.request(request)

      parse!(response)
    end

    # parse the api response
    def parse!(response)
      case response.code.to_i
      when 204, 205
        nil
      when 200...300
        JSON.parse(response.body) if response.body.present?
      when 401
        fail Errors::NotAuthorized, JSON.parse(response.body)['error']
      when 404
        fail Errors::NotFound, JSON.parse(response.body)['error']
      when 422
        handle_response_422(response)
      when 503
        fail Errors::RequestToLong, response.body
      else
        fail Errors::InvalidResponse, "Response code: #{response.code} message: #{response.body}"
      end
    end

    def handle_response_422(response)
      data = JSON.parse(response.body)
      if data['validation_errors'] &&
         data['validation_errors']['email'] &&
         data['validation_errors']['email'].include?('candidate already exists')
        fail Errors::AlreadyExists, data['error']
      else
        fail Errors::NotFound, data['error']
      end
    end

    # default headers for authentication and JSON support
    def headers
      {
        'Accept'        => 'application/json',
        'Authorization' => "Bearer #{api_key}",
        'Content-Type'  => 'application/json',
        'User-Agent'    => 'Workable Ruby Client'
      }
    end

    # transform input using given method if defined
    # @param type [Symbol] type of the transformation, only `[:candidate]` supported so far
    # @param result [Hash|Array|nil] the value to transform, can be nothing, `Hash` of values or `Array` of `Hash`es
    # @return transformed input if transformation exists for type, raw input otherwise
    def transform_from(type, input)
      transform(@transform_from[type], input)
    end

    def build_collection(url, transform_mapping, root_key, params = {})
      url = url.gsub(/#{api_url}\/?/, '')
      response = get_request(url, params)

      Collection.new(
        data: @transform_to.apply(transform_mapping, response[root_key]),
        next_page_method: method(__callee__),
        transform_mapping: transform_mapping,
        root_key: root_key,
        paging: response['paging'])
    end

    def configuration_error(message)
      fail Errors::InvalidConfiguration, message
    end
  end
end
