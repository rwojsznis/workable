module Workable
  module Errors
    class WorkableError        < StandardError; end
    class InvalidConfiguration < WorkableError; end
    class NotAuthorized        < WorkableError; end
    class InvalidResponse      < WorkableError; end
  end
end
