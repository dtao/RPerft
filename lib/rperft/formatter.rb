module RPerft
  class Formatter < RSpec::Core::Formatters::BaseTextFormatter
    def initialize(client)
      @client = client
    end

    def example_started(example)
      @current_example_started = Time.now
    end

    def example_passed(example)
      @client.add_result(example.description, Time.now - @current_example_started)
    end
  end
end
