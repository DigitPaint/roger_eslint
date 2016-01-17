require File.dirname(__FILE__) + "/../lib/roger_eslint/lint.rb"
require "test/unit"

# Fake tester to pass into the linter plugin
class TesterStub
  attr_reader :messages
  attr_writer :files

  def initialize
    @messages = []
    @files = []
  end

  def log(_, message)
    @messages.push(message)
  end

  def warn(_, message)
    @messages.push(message)
  end

  def get_files(_, _)
    @files
  end
end

# Linting plugin unit test
class LintTest < Test::Unit::TestCase
  def setup
  end

  def test_detect_eslint
    assert_nothing_raised do
      lint_file "test.js"
    end

    assert_raise(ArgumentError) do
      lint_file "test.js", eslint: "eslint-blabla"
    end
  end

  def test_lint_nonexisting_file
    success, messages = lint_file("test/data/does_not_exist.js")

    assert success
    assert_equal "No files linted", messages[0]
  end

  def test_lint_with_default_eslintrc
    eslintrc_file = ".eslintrc.js"
    assert !File.exist?(eslintrc_file), ".eslintrc.js file already exists."
    FileUtils.cp("./test/data/.eslintrc-no-undef.js", eslintrc_file)

    file = "test/data/error.js"
    success, messages = lint_file(file)

    assert !success

    assert_equal("#{file}: 1:1 [Error] \"x\" is not defined.", messages[0])
    assert_equal("#{file}: 2:1 [Error] \"alert\" is not defined.", messages[2])
    assert_equal("#{file}: 2:7 [Error] \"x\" is not defined.", messages[4])
  ensure
    File.unlink eslintrc_file
  end

  def test_lint_pass_eslint_options
    file = "test/data/globals.js"
    success, messages = lint_file(file, eslint_options: ["--no-eslintrc", "--global", "my_global"])
    assert success
    assert_equal "#{file}: OK", messages[0]
  end

  def test_lint_fixable_errors
    file = "test/data/fixable.js"
    success, messages = lint_file(file, eslint_options: ["--no-eslintrc", "--rule", "semi: 2"])
    assert !success
    assert_equal "#{file}: 1:15 [Error (Fixable)] Missing semicolon.", messages[0]
    assert_equal "1 problems can be fixed automatically. Run:", messages[2]
  end

  protected

  def lint_file(file, options = {})
    faketester = TesterStub.new
    faketester.files = [file]

    linter = RogerEslint::Lint.new options
    success = linter.call(faketester, {})

    messages = faketester.messages

    # Chop off the first message is it just says "ESLinting files"
    messages.shift

    [success, messages]
  end
end
