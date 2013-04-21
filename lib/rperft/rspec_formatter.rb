require "rspec/core/formatters/base_text_formatter"

module RPerft
  class RSpecFormatter < RSpec::Core::Formatters::BaseTextFormatter
    def initialize(*args)
      super

      # Need to figure out a way to make this configurable.
      @client = RPerft::Client.new("RSpec Performance Tests")
    end

    def example_started(example)
      @current_example_started = Time.now
    end

    def example_passed(example)
      @client.add_result(example.description, Time.now - @current_example_started)
    end

    def dump_summary(*args)
      @client.submit_results(`git log --oneline HEAD^..HEAD`)
    end
  end
end
