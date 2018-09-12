# frozen_string_literal: true

require 'open3'
require_relative '../command'
require_relative '../renderer'
require_relative '../tracer'
require_relative '../models/trace_options'
require_relative '../validators/option_validator'
require_relative '../errors/render'

module B3
  module Commands
    class Trace < B3::Command
      def initialize(options, process_segments: nil)
        @options = B3::Model::TraceOptions.new(options)
        @process_segments = process_segments
      rescue B3::Error::Validation => e
        puts "#{e.message}: Option '#{e.option.to_s.underline}' with value #{e.value.inspect.red}"
      end

      def execute(input: $stdin, output: $stdout)
        renderer = B3::Renderer.new({})

        exit_status = B3::Tracer.trace(@process_segments, @options) do |traced_line, original_line|
          begin
            renderer.render(traced_line)
          rescue B3::Error::Render => e
            puts "Failed to parse line:\n#{original_line}".bold.red
          end
        end

        puts "process exit: #{exit_status}"
      rescue B3::Error::Strace => e
        print 'strace error: '.bold
        puts e.output.red
      end
    end
  end
end
