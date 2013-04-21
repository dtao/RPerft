require "benchmark"
require "cgi"
require "httparty"
require "json"
require "yaml"

module RPerft
  class Client
    include HTTParty

    class TestResult
      attr_reader :description, :elapsed_seconds

      def initialize(description, elapsed_seconds)
        @description = description
        @elapsed_seconds = elapsed_seconds
      end
    end

    def initialize(name)
      @name = name
      @test_results = []
      @configuration = nil
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
      measurement = Benchmark.measure(&block)
      @test_results << TestResult.new(description, measurement.total)
    end

    def add_result(description, elapsed_seconds)
      @test_results << TestResult.new(description, elapsed_seconds)
    end

    def submit_results(comment)
      configure! if !configured?

      results = @test_results.map do |result|
        {
          :description     => result.description,
          :elapsed_seconds => result.elapsed_seconds
        }
      end

      RPerft::Client.post("/projects/#{@project}/#{CGI.escape(@name)}", {
        :body => {
          :comment => comment,
          :results => results
        },
        :headers => {
          "Content-Type" => "application/x-www-form-urlencoded"
        }
      })
    end
  end
end
