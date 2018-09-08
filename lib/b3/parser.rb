module B3
  class Parser
    def self.parse(line)
      # TODO efficiently remove lines beginning with "+++" (strace exit line)

      return unless line

      data = line.scrub.match(pattern)
      return unless data.is_a?(MatchData)

      data.named_captures
    end

    private

    def self.pattern
      /
        ^
        (?:(?<pid>\d+)?\s*)?      # The PID of the process under trace (optional, missing if no fork)
        (?<syscall>[^\(]*)        # The syscall's name
        \s*\(
        (?<args>[^\)]*)?\s*\)     # The arguments passed to the syscall
        \s*=\s*
        (?<result>[^<]*)          # The result of the syscall
        \s*
        (?:<(?<time>[\d\.]+)>)?   # The processing time of the syscall
        $
      /mx
    end
  end
end