require 'json'

module B3
  module Model
    class ParsedSyscall
      attr_reader :pid, :syscall, :args, :result, :timing

      def initialize(data)
        @pid = data[:pid].nil? ? nil : data[:pid].to_i
        @syscall = data[:syscall].to_s
        @args = data[:arguments]
        @result = data[:result] =~ /-?[0-9]+/ ? data[:result].to_i : data[:result].to_s
        @timing = data[:timing].to_f
      end

      def to_json
        {
            :pid => pid,
            :syscall => syscall,
            :args => args,
            :result => result,
            :timing => timing
        }.to_json
      end
    end
  end
end