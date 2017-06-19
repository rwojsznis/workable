# Workable

[![Code Climate](https://codeclimate.com/github/emq/workable/badges/gpa.svg)](https://codeclimate.com/github/emq/workable)
[![Build Status](https://travis-ci.org/emq/workable.svg?branch=master)](https://travis-ci.org/emq/workable)
[![Coverage Status](https://coveralls.io/repos/emq/workable/badge.png?branch=master)](https://coveralls.io/r/emq/workable?branch=master)
[![Gem Version](https://badge.fury.io/rb/workable.svg)](http://badge.fury.io/rb/workable)
[![Dependency Status](https://gemnasium.com/emq/workable.svg)](https://gemnasium.com/emq/workable)

Dead-simple Ruby API client for [workable.com][1]. No extra runtime dependencies.

Uses v3 API provided by workable.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'workable'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install workable

## Usage

Gem covers all endpoints mentioned in official v3 workable API documentation (https://workable.readme.io/docs/).

### Example

For detailed documentation please refer to: http://www.rubydoc.info/gems/workable

``` ruby
client = Workable::Client.new(api_key: 'api_key', subdomain: 'your_subdomain')

# takes optional phase argument (string): 'published' (default), 'draft', 'closed' or 'archived'
client.jobs # => Workable::Collection

# Workable::Collection example
jobs = client.jobs
loop do
  jobs.each do |job|
    # Do something with the job
  end
  break unless jobs.next_page?
  jobs = jobs.fetch_next_page
end

shortcode = client.jobs.first["shortcode"]

# API queries are not cached (at all) - it's up to you to cache results one way or another

client.stages     # => Array of hashes
client.recruiters # => Array of hashes
client.job_details(shortcode)    # => Hash
client.job_questions(shortcode)  # => Array of hashes
client.job_application_form(shortcode) # => Hash
client.job_candidates(shortcode, :stage => stage_slug, :limit => 100) # => Array of hashes:
#   if given stage limits to given stage
#   if given limit lists the last `limit` added candidates

# Adding candidates - candidate is a Hash as described in:
#   http://resources.workable.com/add-candidates-using-api

client.create_job_candidate(candidate, shortcode, stage_slug) # => Hash (stage_slug is optional)

# Possible errors (each one inherits from Workable::Errors::WorkableError)
Workable::Errors::InvalidConfiguration # missing api_key / subdomain
Workable::Errors::NotAuthorized   # wrong api key
Workable::Errors::InvalidResponse # something went wrong during the request?
Workable::Errors::NotFound        # 404 from workable
Workable::Errors::RequestToLong   # When the requested result takes to long to calculate, try limiting your query
```

## Transformations

When creating `Client` you can specify extra methods/`Proc`s for
automated transformation of results and input.

### Example

```ruby
client = Workable::Client.new(
  api_key: 'api_key',
  subdomain: 'your_subdomain'
  transform_to: {
    candidate: OpenStruct.method(:new)
  }
  transform_from: {
    candidate: Proc.new { |input| input.to_h }
  }
)
```

The first transformation `to` will make the `Client` return
`OpenStruct.new(result)` instead of just plain `result` everywhere where
candidate is expected. In case of Arrays the transformation will be
applied to every element.

The second transformation `from` will expect an instance of `OpenStruct`
instead of raw data and will execute the `to_h` on the instance before
sending it to workable API.

The rest of result will be returned as `Array`s/`Hash`es,
no transformation will be applied if not defined - raw data will be
returned.


## Contributing

1. Fork it ( https://github.com/emq/workable/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

[1]: http://workable.com/
