module B3
  module Error
    class Render < StandardError
      attr_reader :data

      def initialize(msg = nil, data = nil)
        @data = data
        super(msg)
      end
    end
  end
end