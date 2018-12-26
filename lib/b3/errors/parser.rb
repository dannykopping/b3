module B3
  module Error
    class ParserError < StandardError
      attr_reader :parse_failure

      def initialize(msg, parse_failure = nil)
        super(msg)
        @parse_failure = parse_failure
      end
    end
  end
end