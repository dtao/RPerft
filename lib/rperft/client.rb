require "benchmark"
require "cgi"
require "httparty"
require "json"
require "yaml"

module RPerft
  class Client
    include HTTParty

    class TestResult
      attr_reader :description, :benchmark

      def initialize(description, &block)
        @description = description
        @benchmark = Benchmark.measure(&block)
      end
    end

    def initialize(name)
      @name = name
      @test_results = []
    end

    def configure!(config_path=nil)
      # If a config path wasn't specified, let's assume it's in the working
      # directory.
      config_path ||= File.join(Dir.pwd, ".perft-config")
      @configuration = YAML.load_file(config_path)

      @host    = @configuration["host"]
      @project = @configuration["project"]
      @machine = @configuration["machine"]
      @api_key = @configuration["api_key"]

      RPerft::Client.base_uri @host
      RPerft::Client.basic_auth @machine, @api_key
    end

    def configured?
      !!@configuration
    end

    def run_test(description, &block)
      @test_results << TestResult.new(description, &block)
    end

    def submit_results
      configure! if !configured?

      results = @test_results.map do |result|
        {
          :description     => result.description,
          :elapsed_seconds => result.benchmark.total
        }
      end

      RPerft::Client.post("/projects/#{@project}/#{CGI.escape(@name)}", {
        :body => { :results => results }
      })
    end
  end
end
