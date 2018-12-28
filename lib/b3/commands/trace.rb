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
        puts "#{e.message}\nOption '#{e.option.to_s.underline}' with value #{e.value.inspect.red}"
        exit 1
      end

      def execute(input: $stdin, output: $stdout)
        @renderer = B3::Renderer.new({})

        # TODO: neaten this up - move into own command?
        exit_status = nil
        if @options.input_file
          File.open(@options.input_file, 'r') do |file|
            file.each_line.lazy.each do |line|
              parsed_line = Parser.parse(line.to_s)
              render(parsed_line, line)
            end
          end
        else
          exit_status = B3::Tracer.trace(@process_segments, @options, &method(:render))
        end

        puts "process exit: #{exit_status}"
      rescue B3::Error::Strace => e
        print 'strace error: '.bold
        puts e.output.red
      end

      def render(parsed_line, original_line)
        puts original_line if @options.debug

        return nil unless parsed_line
        # @renderer.render(parsed_line)
        puts parsed_line.to_json
      rescue B3::Error::Render => e
        puts "Failed to parse line:\n#{original_line}".bold.red
      end
    end
  end
end
