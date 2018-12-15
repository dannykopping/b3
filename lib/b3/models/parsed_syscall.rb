module B3
  module Model
    class ParsedSyscall
      attr_reader :pid, :syscall, :args, :result, :time

      def initialize(data)
        @pid = data['pid'].to_i
        @syscall = data['syscall'].to_s
        @args = data['args'].is_a?(Array) ? data['args'] : []
        @result = data['result'].to_i
        @time = data['time'].to_f
      end
    end
  end
end