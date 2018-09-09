# frozen_string_literal: true

require 'open3'
require_relative '../command'
require_relative '../parser'
require_relative '../syscalls'
require_relative '../renderer'
require_relative '../errors/render'

module B3
  module Commands
    class Trace < B3::Command
      def initialize(options, process_segments: nil)
        @options = options
        @process_segments = process_segments
      end

      def execute(input: $stdin, output: $stdout)
        lines = []
        unparseable_lines = []

        Open3.popen2e('strace', '-f', '-T', *@process_segments) do |_, o, thr|
          t = Thread.new do

            while (line = o.gets) do
              if line.nil?  or line.chomp == ''
                puts '-'
                next
              end

              parsed = Parser.parse(line)
              if parsed.nil?
                unparseable_lines << line
                next
              end

              lines << parsed
              B3::Renderer.output(parsed)
            end
          end
          t.abort_on_exception = true

          thr.join
        end
      rescue IOError => e
        if e.message == 'stream closed'
          puts 'stream closed'
        else
          require 'byebug'
          byebug
        end
      rescue B3::Error::Render => e
        puts 'render error!'
        require 'byebug'
        byebug
      rescue => e
        require 'byebug'
        byebug
      end
    end
  end
end
