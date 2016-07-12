require File.dirname(__FILE__) + "/../lib/roger_eslint/lint.rb"
require "test/unit"
require "roger/testing/mock_project"

# Fake tester to pass into the linter plugin
class TesterStub
  attr_reader :messages
  attr_writer :files

  def initialize
    @messages = []
    @files = []
  end

  def project
    # Creating a mock project with path will forego the construct creation
    @project ||= Roger::Testing::MockProject.new(".")
  end

  def destroy
    @project.destroy if @project
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
      lint_files "test.js"
    end

    assert_raise(ArgumentError) do
      lint_files "test.js", eslint: "eslint-blabla"
    end
  end

  def test_lint_nonexisting_file
    success, messages = lint_files("test/data/does_not_exist.js")

    assert success
    assert_equal "No files linted", messages[0]
  end

  def test_lint_multiple_files
    success, messages = lint_files(
      ["test/data/error.js", "test/data/fixable.js"],
      eslint_options: ["--no-eslintrc", "--rule", "semi: 2"]
    )

    assert !success

    assert_equal("test/data/error.js: OK", messages[0])
    assert_equal("test/data/fixable.js: 1:15 [Error (Fixable)] Missing semicolon.", messages[1])
  end

  def test_lint_with_default_eslintrc
    eslintrc_file = ".eslintrc.js"
    assert !File.exist?(eslintrc_file), ".eslintrc.js file already exists."
    FileUtils.cp("./test/data/.eslintrc-no-undef.js", eslintrc_file)

    file = "test/data/error.js"
    success, messages = lint_files(file)

    assert !success

    assert_equal("#{file}: 1:1 [Error] 'x' is not defined.", messages[0])
    assert_equal("#{file}: 2:1 [Error] 'alert' is not defined.", messages[2])
    assert_equal("#{file}: 2:7 [Error] 'x' is not defined.", messages[4])
  ensure
    File.unlink eslintrc_file
  end

  def test_lint_pass_eslint_options
    file = "test/data/globals.js"
    success, messages = lint_files(file, eslint_options: ["--no-eslintrc", "--global", "my_global"])
    assert success
    assert_equal "#{file}: OK", messages[0]
  end

  def test_lint_fixable_errors
    file = "test/data/fixable.js"
    success, messages = lint_files(file, eslint_options: ["--no-eslintrc", "--rule", "semi: 2"])
    assert !success
    assert_equal "#{file}: 1:15 [Error (Fixable)] Missing semicolon.", messages[0]
    assert_equal "1 problems can be fixed automatically. Run:", messages[2]
  end

  protected

  def lint_files(files, options = {})
    faketester = TesterStub.new
    faketester.files = files.is_a?(Array) ? files : [files]

    linter = RogerEslint::Lint.new options
    success = linter.call(faketester, {})

    messages = faketester.messages

    # Chop off the first message is it just says "ESLinting files"
    messages.shift

    [success, messages]
  ensure
    faketester.destroy
  end
end
