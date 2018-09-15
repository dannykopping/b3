module B3
  module Model
    class TraceOptions
      attr_reader :pids
      attr_reader :input_file

      def initialize(options)
        B3::Validator::OptionValidator::validate!(options)

        # TODO: neaten this up
        @pids = options[:pids]
        @input_file = options[:input_file]
      end
    end
  end
end