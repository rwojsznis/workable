module Workable
  class Collection
    extend Forwardable
    def_delegators :@data, :size, :each, :[], :map, :first

    attr_reader :data

    def initialize(data, next_page_method, paging = nil)
      @data = data

      if paging
        @next_page = paging['next']
        @next_page_method = next_page_method
      end
    end

    def next_page?
      @next_page
    end

    def fetch_next_page
      return unless next_page?

      params = CGI.parse(URI.parse(@next_page).query)
      @next_page_method.call(params)
    end
  end
end
