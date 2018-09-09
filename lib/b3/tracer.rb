require_relative 'parser'
require_relative 'syscalls'

module B3
  class Tracer
    # thanks https://nickcharlton.net/posts/ruby-subprocesses-with-stdout-stderr-streams.html
    def self.trace(process_segments, &block)
      exit_status = nil

      Open3.popen3('strace', *strace_flags, *process_segments) do |stdin, stdout, stderr, proc_thread|
        read_thread = Thread.new do
          while (line = stderr.gets) do
            yield Parser.parse(line.to_s), line if block_given?
          end
        end

        # proc_thread.report_on_exception = true
        # read_thread.report_on_exception = true

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
    rescue B3::Error::Render => e
      puts "render error! #{e.data}"
    end

    private

    def self.strace_flags
      [
          '-f',       # follow forks
          '-D',       # Run as a detached grandchild, not parent
          '-T',       # show time spent in syscall
          '-s 1000',  # show n bytes of strings # TODO make configurable
          '-qq',      # suppress messages about process exit status
      ]
    end
  end
end