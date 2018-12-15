require_relative 'errors/strace'
require_relative 'errors/parser'
require_relative 'models/parsed_syscall'
require_relative 'arguments_parser'

module B3
  class Parser
    #
    # @return B3::Model::ParsedSyscall
    #
    def self.parse(line, debug: false)
      raise B3::Error::ParserError, 'Empty line' unless line

      raise B3::Error::Strace.new('strace encountered an error', line) if line.start_with?('strace:')

      data = line.scrub.match(pattern)
      raise B3::Error::ParserError, 'Failed to match pattern' unless data.is_a?(MatchData)

      parsed = data.named_captures
      raise B3::Error::ParserError, 'Failed to match pattern' unless parsed

      parsed['args'] = ArgumentsParser.parse(parsed['args'])
      B3::Model::ParsedSyscall.new(parsed).freeze
    rescue B3::Error::ParserError => e
      # suppress exceptions unless `debug` flag is passed
      return nil unless debug

      raise e
    end

    private

    def self.pattern
      # see tests @ https://regex101.com/r/amYK9q/2
      /
        ^
        (?:\[pid\s*)?(?<pid>\d+)?(?:\]?)\s*      # The PID of the process under trace (optional, missing if no fork)
        (?<syscall>[^\(]*)                       # The syscall's name
        \s*\(
        (?<args>[^\)]*)?\s*\)                    # The arguments passed to the syscall
        \s*=\s*
        (?<result>[^<]*)                         # The result of the syscall
        \s*
        (?:<(?<time>[\d\.]+)>)?                  # The processing time of the syscall
        $
      /mx
    end
  end
end