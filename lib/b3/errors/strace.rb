module B3
  module Error
    class Strace < StandardError
      attr_reader :output

      def initialize(msg = nil, output = nil)
        @output = output
        super(msg)
      end
    end
  end
end