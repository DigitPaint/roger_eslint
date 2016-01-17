require "shellwords"
require "json"
require "roger/test"

module RogerEslint
  # JS linter plugin for Roger
  class Lint
    # ESLint severities translated into a human readable format
    ESLINT_SEVERITIES = {
      1 => "Warning",
      2 => "Error"
    }.freeze

    # @param [Hash] options The options
    # @option options [Array] :match Files to match
    # @option options [Array[Regexp]] :skip Array of regular expressions to skip files
    # @option options [Boolean] (false) :fail_on_warning Wether or not to fail test on warnings
    # @option options [String] :eslint eslint command
    # @option options [Array] :eslint_options An array of eslint options; make sure
    #   you have the commandline flag and the value in separate elments, so: `["--global", "$"]`
    def initialize(options = {})
      @options = {
        match: ["html/**/*.js"],
        skip: [],
        fail_on_warning: false,
        eslint: "eslint",
        eslint_options: []
      }

      @options.update(options) if options
    end

    def lint(test, file_path)
      output = `#{eslint_command(file_path)}`
      file_lints = JSON.parse(output).first

      unless file_lints
        test.warn(self, "No files linted")
        return true
      end

      success = file_lints["errorCount"] <= 0
      success &&= file_lints["warningCount"] <= 0 if @_call_options[:fail_on_warning]

      fixables = []

      if success
        test.log(self, "#{file_path}: OK")
      else
        file_lints["messages"].each do |message|
          fixables << message if message["fix"]
          report_message(test, file_path, message)
        end
      end

      report_fixables(test, file_path, fixables)

      success
    end

    # @param [Hash] options The options
    # @option options [Array] :match Files to match
    # @option options [Array[Regexp]] :skip Array of regular expressions to skip files
    def call(test, options)
      @_call_options = {}.update(@options).update(options)

      detect_eslint

      test.log(self, "ESLinting files")

      failures = test.get_files(@_call_options[:match], @_call_options[:skip]).select do |file_path|
        !lint(test, file_path)
      end
      failures.empty?
    ensure
      @_call_options = {}
    end

    private

    def eslint_command(file_path, extras = [])
      command = [
        @_call_options[:eslint],
        "-f", "json"
      ]

      command += @_call_options[:eslint_options] if @_call_options[:eslint_options]

      command += extras
      command << file_path

      Shellwords.join(command)
    end

    def report_message(test, file_path, message)
      output = "#{file_path}: "
      output << message["line"].to_s
      output << ":"
      output << message["column"].to_s
      output << " ["
      output << ESLINT_SEVERITIES[message["severity"]]
      output << " (Fixable)" if message["fix"]
      output << "] "
      output << message["message"]

      test.log(self, output)
      test.log(self, "  #{message['source']}")
    end

    def report_fixables(test, file_path, fixables)
      if fixables.any?
        test.log(self, "#{fixables.size} problems can be fixed automatically. Run:")
        test.log(self, "  #{eslint_command(file_path, ['--fix'])}")
      end
    end

    def detect_eslint
      command = [@_call_options[:eslint], "-v", "2>/dev/null"]
      detect = system(Shellwords.join(command))
      unless detect
        err = "Could not find eslint. Install eslint using: 'npm install -g eslint'."
        fail ArgumentError, err
      end
    end
  end
end

Roger::Test.register :eslint, RogerEslint::Lint
