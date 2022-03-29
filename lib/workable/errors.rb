module Workable
  module Errors
    class WorkableError        < StandardError; end
    class InvalidConfiguration < WorkableError; end
    class NotAuthorized        < WorkableError; end
    class Forbidden            < WorkableError; end
    class InvalidResponse      < WorkableError; end
    class NotFound             < WorkableError; end
    class AlreadyExists        < WorkableError; end
    class RequestToLong        < WorkableError; end
    class RateLimitExceeded    < WorkableError; end
  end
end
