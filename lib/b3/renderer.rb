require 'colorize'

require_relative 'errors/render'

module B3
  class Renderer
    def self.output(data)
      return nil unless data.is_a?(Hash)

      @data = data

      puts "#{pid}#{syscall}#{args}#{result}#{time}"
    end

    private

    def self.pid
      return nil unless @data['pid']

      "[pid #{@data['pid'].bold}] "
    end

    def self.syscall
      category = Syscalls.categorise(@data['syscall'])
      raise B3::Error::Render 'Cannot print uncategorised line', @data unless category

      colour = B3::Syscalls::Category.colour(category)
      "#{@data['syscall'].colorize(color: colour).bold}"
    end

    def self.args
      return '()' unless @data['args']

      "(#{@data['args'].scrub.strip})"
    end

    def self.result
      return nil unless @data['result']

      " = #{@data['result'].scrub.strip}"
    end

    def self.time
      return nil unless @data['time']

      " (#{@data['time'].scrub.strip}s)"
    end
  end
end