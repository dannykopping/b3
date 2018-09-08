# frozen_string_literal: true

require 'thor'

module B3
  # Handle the application command line parsing
  # and the dispatch to various command objects
  #
  # @api public
  class CLI < Thor
    # Error raised by this runner
    Error = Class.new(StandardError)

    desc 'version', 'b3 version'
    def version
      require_relative 'version'
      puts "v#{B3::VERSION}"
    end
    map %w(--version -v) => :version

    desc 'trace [PROCESS...]', 'Trace a process'
    method_option :help, aliases: '-h', type: :boolean,
                         desc: 'Display usage information'
    method_option :pids, aliases: '-p', type: :array,
                         desc: 'Trace the given PIDs'
    def trace(*process)
      if options[:help]
        invoke :help, ['trace']
      else
        require_relative 'commands/trace'
        B3::Commands::Trace.new(options, process_segments: process).execute
      end
    end
  end
end
