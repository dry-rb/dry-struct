# frozen_string_literal: true

require "tempfile"
require "spec_helper"

RSpec.describe Dry::Struct do
  let(:output_start_marker) do
    /(expected:)|(Expected )/
  end

  let(:output_end_marker) do
    /#{output_start_marker.source}|Finished/
  end

  def run_spec(code)
    temp_spec = Tempfile.new(["failing_spec", ".rb"])
    temp_spec.write(<<~RUBY)
      require "dry/struct"

      RSpec.describe "A failing example" do
        before(:all) do
          Dry::Struct.load_extensions(:super_diff)
        end

        #{code}
      end
    RUBY
    temp_spec.close

    process_output(`rspec #{temp_spec.path}`, temp_spec.path)
  end

  def process_output(output, path)
    uncolored = output.gsub(/\e\[([;\d]+)?m/, "")
    # cut out significant lines
    lines = extract_diff(uncolored, path)
    prefix = lines.filter_map { |line|
      line.match(/^\A(\s+)/).to_s unless line.strip.empty?
    }.min
    processed_lines = lines.map { |line| line.gsub(prefix, "") }
    remove_banner(processed_lines).join.gsub("\n\n\n", "\n\n").gsub(/\n\n\z/, "\n")
  end

  # remove this part from the output:
  #
  # Diff:
  #
  # ┌ (Key) ──────────────────────────┐
  # │ ‹-› in expected, not in actual  │
  # │ ‹+› in actual, not in expected  │
  # │ ‹ › in both expected and actual │
  # └─────────────────────────────────┘
  #
  def remove_banner(lines)
    before_banner = lines.take_while { |line| !line.start_with?("Diff:") }
    after_banner = lines.drop_while { |line|
      !line.include?("└")
    }.drop(1)
    before_banner + after_banner
  end

  def extract_diff(output, path)
    output.lines.drop_while { |line|
      !line[output_start_marker]
    }.take_while.with_index { |line, idx|
      idx.zero? || !(line.include?(path) || line[output_start_marker])
    }
  end

  it "produces a nice diff" do
    output = run_spec(<<~RUBY)
      let(:user_type) do
        module Test
          class User < Dry::Struct
            attribute :name, 'string'
            attribute :age, 'integer'
          end
        end

        Test::User
      end

      let(:user) do
        user_type[name: "Jane", age: 21]
      end

      let(:other_user) do
        user_type[name: "Jane", age: 22]
      end

      example "failing" do
        expect(user).to eql(other_user)
      end
    RUBY

    expect(output).to eql(<<~DIFF)
      expected: #<Test::User name: "Jane", age: 22>
           got: #<Test::User name: "Jane", age: 21>

      (compared using eql?)

        #<Test::User {
          name: "Jane",
      -   age: 22
      +   age: 21
        }>
    DIFF
  end
end
