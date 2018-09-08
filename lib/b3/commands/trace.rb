# frozen_string_literal: true

require 'open3'
require_relative '../command'
require_relative '../parser'

module B3
  module Commands
    class Trace < B3::Command
      def initialize(options, process_segments: nil)
        @options = options
        @process_segments = process_segments
      end

      def execute(input: $stdin, output: $stdout)
        lines = []

        Open3.popen2e('strace', '-f', '-T', *@process_segments) do |_, o, thr|
          Thread.new do
            while line = o.gets do
              puts line
              # puts Parser.parse(line)
            end
          end


          puts thr.value
          thr.join
          #
          # lines.each do |line|
          #   puts "SYSCALL: #{line['syscall']} => #{line['result']}"
          # end
        end
      end
    end
  end
end
