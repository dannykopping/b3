# frozen_string_literal: true

require 'open3'
require_relative '../command'
require_relative '../renderer'
require_relative '../tracer'

module B3
  module Commands
    class Trace < B3::Command
      def initialize(options, process_segments: nil)
        @options = options
        @process_segments = process_segments
      end

      def execute(input: $stdin, output: $stdout)
        renderer = B3::Renderer.new({})

        exit_status = B3::Tracer.trace(@process_segments) do |traced_line, original_line|
          begin
            renderer.render(traced_line)
          rescue B3::Error::Render => e
            puts "Failed to parse line:\n#{original_line}".bold.red
          end
        end

        puts "process exit: #{exit_status}"
      end
    end
  end
end
