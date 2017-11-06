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

    # create a comment on the candidate's timeline
    # @param candidate_id [Number|String] the candidate's id
    # @param member_id [Number|String] id of the member leaving the comment
    # @param comment_text [String] the comment's text
    # @param policy [String] option to set the view rights of the comment
    # @param attachment [Hash] optional attachment for the comment
    # @param attachment :name [String] filename of the attachment
    # @param attachment :data [String] payload of the attachment, encoded in base64
    def create_comment(candidate_id, member_id, comment_text, policy=[], attachment=nil)
      comment = { body: comment_text, policy: policy, attachment: attachment }

      post_request("candidates/#{candidate_id}/comments") do |request|
        request.body = {member_id: member_id.to_s, comment: comment}.to_json
      end
    end

    # disqualify a candidate
    # @param candidate_id [Number|String] the candidate's id
    # @param member_id [Number|String] id of the member performing the disqualification
    # @param reason [String] why the candidate should be disqualified
    def disqualify(candidate_id, member_id, reason=nil)
      post_request("candidates/#{candidate_id}/disqualify") do |request|
        request.body = {member_id: member_id.to_s, disqualification_reason: reason}.to_json
      end
    end

    # revert a candidate's disqualification
    # @param candidate_id [Number|String] the candidate's id
    # @param member_id [Number|String] id of the member reverting the disqualification
    def revert(candidate_id, member_id)
      post_request("candidates/#{candidate_id}/revert") do |request|
        request.body = {member_id: member_id.to_s}.to_json
      end
    end

    # copy a candidate to another job
    # @param candidate_id [Number|String] the candidate's id
    # @param member_id [Number|String] id of the member performing the copy
    # @param shortcode [String] shortcode of the job that the candidate will be copied to
    # @param stage [String] stage the candidate should be copied to
    def copy(candidate_id, member_id, shortcode, stage=nil)
      body = {
        member_id: member_id,
        target_job_shortcode: shortcode,
        target_stage: stage
      }

      response = post_request("candidates/#{candidate_id}/copy") do |request|
        request.body = body.to_json
      end

      @transform_to.apply(:candidate, response['candidate'])
    end

    # moves a candidate to another job
    # @param candidate_id [Number|String] the candidate's id
    # @param member_id [Number|String] id of the member performing the relocation
    # @param shortcode [String] shortcode of the job that the candidate will be moved to
    # @param stage [String] stage the candidate should be moved to
    def relocate(candidate_id, member_id, shortcode, stage=nil)
      body = {
        member_id: member_id,
        target_job_shortcode: shortcode,
        target_stage: stage
      }

      response = post_request("candidates/#{candidate_id}/relocate") do |request|
        request.body = body.to_json
      end

      @transform_to.apply(:candidate, response['candidate'])
    end

    # moves a candidate to another stage
    # @param candidate_id [Number|String] the candidate's id
    # @param member_id [Number|String] id of the member performing the move
    # @param stage [String] stage the candidate should be moved to
    def move(candidate_id, member_id, stage)
      post_request("candidates/#{candidate_id}/move") do |request|
        request.body = { member_id: member_id, target_stage: stage }.to_json
      end
    end

    # creates a rating for a candidate
    # @param candidate_id [Number|String] the candidate's id
    # @param member_id [Number|String] id of the member adding the rating
    # @param comment [String] a comment about the scoring of the candidate
    # @param score [String] one of 'negative', 'positive', or 'definitely'
    def create_rating(candidate_id, member_id, comment, score)
      body = {
        member_id: member_id,
        comment: comment,
        score: score
      }

      post_request("candidates/#{candidate_id}/ratings") do |request|
        request.body = body.to_json
      end
    end

    private

    attr_reader :api_key, :subdomain

    # build the url to api
    def api_url
      @_api_url ||= 'https://www.workable.com/spi/v%s/accounts/%s' % [Workable::API_VERSION, subdomain]
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
        JSON.parse(response.body) if !response.body.to_s.empty?
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
