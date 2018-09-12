require_relative '../errors/validation'

module B3
  module Validator
    class OptionValidator
      def self.validate!(options)
        raise ArgumentError unless options.is_a?(Hash)
        return true unless options

        options.each do |option, value|
          case option
          when 'pids'
            raise B3::Error::Validation.new('Invalid PID(s) given', option, value) unless valid_pids?(value.dup)
          end
        end
      end

      private

      def self.valid_pids?(pids)
        return false unless pids

        pids.keep_if {|pid| pid.to_s.match /^\d+$/}.length > 0
      end
    end
  end
end