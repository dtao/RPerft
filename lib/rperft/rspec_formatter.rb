require "rspec/core/formatters/base_text_formatter"

module RPerft
  class RSpecFormatter < RSpec::Core::Formatters::BaseTextFormatter
    def initialize(*args)
      super

      # Need to figure out a way to make this configurable.
      @client = RPerft::Client.new("RSpec Performance Tests")
    end

    def example_started(example)
      super
      @current_example_started = Time.now
    end

    def example_passed(example)
      super
      @client.add_result(example.description, Time.now - @current_example_started)
    end

    def dump_summary(*args)
      super
      @client.submit_results
    end
  end
end
