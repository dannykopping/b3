require 'parslet'

require_relative 'errors/strace'
require_relative 'errors/parser'
require_relative 'models/parsed_syscall'
require_relative 'arguments_parser'

module B3
  class Parser < Parslet::Parser
    root(:syscall_line)

    rule(:syscall_line) { pid.maybe >> syscall >> arguments >> result >> timing.maybe }

    rule(:pid) { (str('[pid') >> space?).maybe >> match(/[0-9]/).repeat(1).as(:pid) >> (space? >> str(']')).maybe >> space? }

    rule(:syscall) { space? >> match(/[_a-zA-Z][_a-zA-Z0-9'"]*/).repeat.as(:syscall) >> space? }

    rule(:arguments) {
      space? >> str('(') >> (
        str(')').absent? >> any
      ).repeat.as(:arguments) >> str(')')
    }

    rule(:result) { space? >> str('=') >> space? >> (str('<').absent? >> any).repeat.as(:result) >> space? }

    rule(:timing) { space? >> str('<') >> match(/[.0-9]/).repeat.as(:timing) >> str('>') >> space? }

    rule(:space?) { match(/\s/).repeat }



    def self.execute(line, debug: false)
      raise B3::Error::ParserError, 'Empty line' unless line

      raise B3::Error::Strace.new('strace encountered an error', line) if line.start_with?('strace:')

      parsed = self.new.parse(line)

      # may contain some whitespace which is probably unavoidable,
      # since the :result can have spaces in it, and timing is optional
      parsed[:result] = parsed[:result].to_s.strip

      # parse arguments separately to reduce complexity of this class
      parsed[:arguments] = ArgumentsParser.execute(parsed[:arguments].to_s)

      puts transform_result(parsed).to_json
    rescue Parslet::ParseFailed => e
      # suppress exceptions unless `debug` flag is passed
      return nil unless debug

      raise B3::Error::ParserError.new('Failed to match pattern', e.parse_failure_cause)
    end

    private

    def self.transform_result(parsed)
      Model::ParsedSyscall.new(parsed).freeze
    end
  end
end