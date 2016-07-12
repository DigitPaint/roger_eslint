require "shellwords"
require "pathname"
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
    # @option options [String, nil] :eslint eslint command, if nil will search for the command
    #   Preferring the local node_modules path.
    # @option options [Array] :eslint_options An array of eslint options; make sure
    #   you have the commandline flag and the value in separate elments, so: `["--global", "$"]`
    def initialize(options = {})
      @options = {
        match: ["html/**/*.js"],
        skip: [%r{vendor\/.*\.js\Z}],
        fail_on_warning: false,
        eslint: nil,
        eslint_options: []
      }

      @options.update(options) if options
    end

    # @return [Array] failed files
    def lint(test, file_paths)
      output = `#{eslint_command(file_paths)}`
      file_lints = JSON.parse(output)

      process_lint_results(test, file_lints)
    end

    # @param [Hash] options The options
    # @option options [Array] :match Files to match
    # @option options [Array[Regexp]] :skip Array of regular expressions to skip files
    def call(test, options)
      @_call_options = {}.update(@options).update(options)

      detect_eslint(test)

      test.log(self, "ESLinting files")

      files = test.get_files(@_call_options[:match], @_call_options[:skip])

      lint(test, files).empty?
    ensure
      @_call_options = {}
    end

    private

    def process_lint_results(test, file_lints)
      if file_lints.empty?
        test.warn(self, "No files linted")
        return []
      end

      file_lints.select do |file_lint|
        path = file_lint["filePath"]

        success = file_lint["errorCount"] <= 0
        success &&= file_lint["warningCount"] <= 0 if @_call_options[:fail_on_warning]

        fixables = []

        if success
          test.log(self, "#{normalize_path(test, path)}: OK")
        else
          file_lint["messages"].each do |message|
            fixables << message if message["fix"]
            report_message(test, path, message)
          end
        end

        report_fixables(test, path, fixables)

        !success
      end
    end

    def eslint_command(file_path, extras = [])
      command = [
        @_call_options[:eslint],
        "-f", "json"
      ]

      command += @_call_options[:eslint_options] if @_call_options[:eslint_options]

      command += extras
      if file_path.is_a? Array
        command += file_path
      else
        command << file_path
      end

      Shellwords.join(command)
    end

    def report_message(test, file_path, message)
      output = "#{normalize_path(test, file_path)}: "
      output << "#{message['line']}:#{message['column']} "
      output << "["
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
        test.log(self, "  #{eslint_command(normalize_path(test, file_path), ['--fix'])}")
      end
    end

    def detect_eslint(test)
      if @_call_options[:eslint]
        commands_to_test = [@_call_options[:eslint]]
      else
        commands_to_test = [
          test.project.path + "node_modules/eslint/bin/eslint.js",
          "eslint.js",
          "eslint"
        ]
      end

      detect = commands_to_test.detect do |command|
        system(Shellwords.join([command, "-v"]) + "> /dev/null 2>&1")
      end

      if detect
        # Bit of a hack to set the value like this
        @_call_options[:eslint] = detect
      else
        err = "Could not find eslint. Install eslint using: 'npm install -g eslint'."
        err += " Or install eslint locally."
        fail ArgumentError, err
      end
    end

    # Will make path relative to project dir
    # @return [String] relative path
    def normalize_path(test, path)
      Pathname.new(path).relative_path_from(test.project.path.realpath).to_s
    end
  end
end

Roger::Test.register :eslint, RogerEslint::Lint
