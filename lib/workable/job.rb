module Workable
  class Job
    # from main jobs query
    attr_reader :key, :title, :full_title, :code, :shortcode, :state,
                :department, :url, :application_url, :shortlink, :location

    # from job details
    attr_reader :full_description, :description, :requirements, :benefits,
                :employment_type, :industry, :function, :experience, :education

    def initialize(params)
      params.each do |key, value|
        value = OpenStruct.new(value) if value.is_a?(Hash)
        instance_variable_set("@#{key}", value)
      end
    end

    def location_name
      "#{location.city}, #{location.country}"
    end

    def created_at
      Date.parse(@created_at)
    end
  end
end
