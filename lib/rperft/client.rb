require "yaml"

module RPerft
  class Client
    class TestResult
      attr_reader :description, :benchmark

      def initialize(description, &block)
        @description = description
        @benchmark = Benchmark.measure(&block)
      end
    end

    def initialize
      @test_results = []
    end

    def configure!(config_path)
      config_path ||= guess_config_path(caller)
      @configuration = YAML.load_file(config_path)
    end

    def configured?
      !!@configuration
    end

    def run_test(description, &block)
      @test_results << TestResult.new(description, &block)
    end

    def submit_results
      
    end

    protected

    def guess_config_path(context)
      # Who knows? Maybe there will be a .perft-config file in the working
      # directory.
      File.join(File.dirname(context.first), ".perft-config")
    end
  end
end
