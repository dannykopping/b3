require_relative 'errors/strace'
require_relative 'errors/parser'
require_relative 'models/parsed_syscall'

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

      parsed['args'] = split_args(parsed['args'])
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

    def self.split_args(args)
      # H/T to https://stackoverflow.com/a/18893443/385265
      split = args.strip.split(/
        ,               # Split on comma
        (?=             # Followed by
           (?:          # Start a non-capture group
             [^{}"]*    # 0 or more non-quote characters
             (?:{|}|")  # 1 quote
             [^{}"]*    # 0 or more non-quote characters
             (?:{|}|")  # 1 quote
           )*           # 0 or more repetition of non-capture group (multiple of 2 quotes will be even)
           [^{}"]*      # Finally 0 or more non-quotes
           $            # Till the end  (This is necessary, else every comma will satisfy the condition)
        )
      /x)

      return [] unless split

      split.map { |arg| arg.to_s.strip }
    end
  end
end