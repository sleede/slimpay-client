module Slimpay
  class Error < StandardError
    def initialize(error_data = {})
      if error_data[:json] && error_data[:json]['message']
        super(error_data[:json]['message'])
      end
    end
  end
end