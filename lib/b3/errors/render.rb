module B3
  module Error
    class Render < StandardError
      def initialize(msg, data)
        @data = data

        super(msg)
      end
    end
  end
end