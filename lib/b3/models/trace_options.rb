module B3
  module Model
    class TraceOptions
      attr_reader :pids

      def initialize(options)
        B3::Validator::OptionValidator::validate!(options)

        # TODO: neaten this up
        @pids = options[:pids]
      end
    end
  end
end