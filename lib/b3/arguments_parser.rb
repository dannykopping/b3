require 'parslet'
require_relative 'arguments'

module B3
  class ArgumentsParser < Parslet::Parser
    include Arguments

    root(:argument_list)

    def self.execute(arguments_str)
      arguments_str = arguments_str.to_s.strip.scrub
      return [] if arguments_str.empty?

      parsed = self.new.parse(arguments_str)
      transform_result(parsed)
    rescue Parslet::ParseFailed => e
      raise e
    end

    private

    def self.transform_result(parsed)
      transformed = Arguments::Transformer.new.apply(parsed)

      # always return result as an array
      transformed = [transformed] unless transformed.is_a?(Array)
      transformed.freeze
    end
  end
end