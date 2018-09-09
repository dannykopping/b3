require 'colorize'

require_relative 'errors/render'

module B3
  class Renderer
    DEFAULT_SETTINGS = {
        :columns => 53
    }

    def initialize(settings = {})
      @settings = DEFAULT_SETTINGS.merge(settings)
    end

    def render(data)
      return nil unless data.is_a?(Hash)

      @data = data

      puts "#{pid}#{syscall}#{result}#{time}"
    end

    private

    def pid
      return nil unless @data['pid']

      "[pid #{@data['pid'].bold}] "
    end

    def syscall
      category = Syscalls.categorise(@data['syscall'])
      raise B3::Error::Render.new('Cannot print uncategorised line', @data) unless category

      colour = B3::Syscalls::Category.colour(category)
      "%-#{@settings[:columns]}s" % "#{@data['syscall'].colorize(color: colour).bold}#{args}"
    end

    def args
      return '()' unless @data['args']

      "(#{@data['args'].scrub.strip})"
    end

    def result
      return nil unless @data['result']

      " = #{@data['result'].scrub.strip}"
    end

    def time
      return nil unless @data['time']

      " (#{@data['time'].scrub.strip}s)"
    end
  end
end