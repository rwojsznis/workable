module Workable
  class Transformation
    def initialize(mappings)
      @mappings = mappings || {}
    end

    # selects transformation strategy based on the inputs
    # @param transformation [Method|Proc|nil] the transformation to perform
    # @param data           [Hash|Array|nil]  the data to transform
    # @return               [Object|nil]
    #    results of the transformation if given, raw data otherwise
    def apply(mapping, data)
      transformation = @mappings[mapping]
      return data unless transformation

      case data
      when nil
        data
      when Array
        data.map { |datas| transformation.call(datas) }
      else
        transformation.call(data)
      end
    end
  end
end
