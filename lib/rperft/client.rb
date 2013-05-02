require "benchmark"
require "cgi"
require "httparty"
require "json"
require "yaml"

module RPerft
  class Client
    include HTTParty

    class TestResult
      attr_reader :description, :repetitions, :elapsed_seconds
      attr_accessor :tags

      def initialize(description, repetitions, elapsed_seconds)
        @description = description
        @repetitions = repetitions
        @elapsed_seconds = elapsed_seconds
        @tags = []
      end
    end

    def initialize(suite_name)
      @suite_name    = suite_name
      @test_results  = []
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

    def run_test(description, repetitions, options={}, &block)
      measurement = Benchmark.measure do
        repetitions.times(&block)
      end
      add_result(description, repetitions, measurement.total, options)
    end

    def add_result(description, repetitions, elapsed_seconds, options={})
      result = TestResult.new(description, repetitions, elapsed_seconds)
      result.tags = options[:tags] || []
      @test_results << result
    end

    def submit_results
      configure! if !configured?

      changeset = nil
      comment   = nil
      changes   = nil

      if (`git status --porcelain`).empty?
        changeset, comment = `git log --oneline HEAD^..HEAD`.split(/\s+/, 2)
        changes = `git diff HEAD^`
      end

      results = @test_results.map do |result|
        {
          :description     => result.description,
          :elapsed_seconds => result.elapsed_seconds,
          :repetitions     => result.repetitions,
          :tags            => result.tags
        }
      end

      RPerft::Client.post("/projects/#{@project}/#{CGI.escape(@suite_name)}", {
        :body => {
          :results   => results,
          :changeset => changeset,
          :comment   => comment,
          :changes   => changes
        },
        :headers => {
          "Content-Type" => "application/x-www-form-urlencoded"
        }
      })
    end
  end
end
