module B3
  module Error
    class Validation < StandardError
      attr_reader :option
      attr_reader :value

      def initialize(msg = nil, option = nil, value = nil)
        @option = option
        @value = value
        super(msg)
      end
    end
  end
end