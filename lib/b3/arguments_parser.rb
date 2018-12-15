module B3
  class ArgumentsParser
    def self.parse(args)
      # H/T to https://stackoverflow.com/a/18893443/385265
      split = args.strip.split(pattern)
      return [] unless split

      split.map do |arg|
        self.coerce(arg)
      end.freeze
    end

    def self.coerce(argument)
      # first normalise
      argument = argument.to_s.strip

      case
      # strings
      when argument =~ /^('|")(.*)('|")$/mx
        $2
      # integers (signed)
      when argument =~ /^-?\d+$/
        argument.to_i
      # NULL
      when argument =~ /^NULL$/
        nil
      else
        argument
      end
    end

    private

    def self.pattern
      /
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
      /x
    end
  end
end