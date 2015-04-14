require 'json'
require 'uri'
require 'net/http'
require 'date'
require 'ostruct'

require_relative "workable/version"
require_relative "workable/errors"
require_relative "workable/client"

module Workable
  API_VERSION = "2".freeze
end
