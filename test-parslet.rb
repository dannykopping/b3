require 'parslet'
require 'awesome_print'
include Parslet

# string = '[{iov_base="something", iov_len=9}, {iov_base="\n", iov_len=1}]'
string = '[  [       1],2 , "bob", ["another \'inner\' bob", \'rad "dude"\']  3    ]'

class Mini < Parslet::Parser
  # separators
  rule(:separator) { match(',') }
  rule(:separator?) { match(',').maybe }

  # arrays
  rule(:array) {
    str('[') >> (
      str('[').absent? >> array_element
    ).repeat.as(:elements) >> str(']')
  }
  rule(:array_element) { space? >> data_structure.as(:element) >> space? >> separator? }

  # ints
  rule(:integer) { match('[0-9]') }

  # strings
  rule(:string) { single_quoted_string | double_quoted_string }
  rule(:double_quoted_string) {
    str('"') >> (
      str('"').absent? >> any
    ).repeat.as(:string) >> str('"')
  }
  rule(:single_quoted_string) {
    str("'") >> (
      str("'").absent? >> any
    ).repeat.as(:string) >> str("'")
  }

  # whitespace
  rule(:space) { match(/\s/).repeat }
  rule(:space?) { match(/\s/).repeat.maybe }

  rule(:data_structure) { array | integer | string }

  root(:data_structure)
end

begin
  ap Mini.new.parse(string)
rescue Parslet::ParseFailed => failure
  puts failure.parse_failure_cause.ascii_tree
end