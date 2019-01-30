require_relative 'parser'
require_relative 'syscalls'
require_relative 'models/trace_options'

module B3
  class Tracer
    # thanks https://nickcharlton.net/posts/ruby-subprocesses-with-stdout-stderr-streams.html
    def self.trace(process_segments, options, &block)
      exit_status = nil

      Thread.abort_on_exception = true

      args = *strace_flags(options)
      args.concat(process_segments) unless process_segments.empty?
      Open3.popen3('strace', *args) do |stdin, stdout, stderr, proc_thread|
        read_thread = Thread.new do
          while (line = stderr.gets) do
            yield Parser.execute(line.to_s), line if block_given?
          end
        end

        read_thread.join
        proc_thread.join

        exit_status = proc_thread.value.exitstatus
      end

      exit_status

    rescue IOError => e
      if e.message == 'stream closed'
        puts 'stream closed'
      else
        require 'byebug'
        byebug
      end
    end

    private

    def self.strace_flags(options = {})
      flags = [
          '-f',       # follow forks
          '-D',       # Run as a detached grandchild, not parent
          '-T',       # show time spent in syscall
          '-s 1000',  # show n bytes of strings # TODO make configurable
          '-qq',      # suppress messages about process exit status
      ]

      if options.is_a?(B3::Model::TraceOptions)

        case true
        when options.pids
          # cannot use this flag when tracing a running process
          flags.delete('-D')
          # trace given PIDs
          flags.concat(['-p', options.pids.join(',')])
        end
      end

      flags
    end
  end
end