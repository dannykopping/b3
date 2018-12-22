require 'parslet'
require 'awesome_print'
include Parslet


#
#
# match strings in object that are not quoted (flags as separate datatype? are strings always quoted?)
#
#
#

string = '[{iov_len=9000000001}, 90, {bob={inner="hello"}}]'
# string = '[  [       1],2 , "bob", ["another \'inner\' bob", \'rad "dude"\']  3, {hello=sally, bob= [1,2,3 ]  }    ]'

class Mini < Parslet::Parser
  # separators
  rule(:separator) { match(',') }
  rule(:separator?) { match(',').maybe }

  # arrays
  rule(:array) {
    str('[') >> (
      str('[').absent? >> array_element
    ).repeat(1).as(:elements) >> str(']')
  }
  rule(:array_element) { space? >> data_structure.as(:element) >> space? >> separator? }

  # objects
  rule(:object) {
    str('{') >> (
    str('{').absent? >> property
    ).repeat(1).as(:properties) >> str('}')
  }

  rule(:property_key) { match(/[a-zA-Z0-9_'"]/).repeat(1) }
  rule(:property_value) { data_structure.repeat(1) }
  rule(:property) { space? >> property_key.as(:key) >> space? >> str('=') >> space? >> property_value.as(:value) >> space? }

  # ints
  rule(:integer) { match('[0-9]').repeat(1) }

  # strings
  rule(:string) { single_quoted_string | double_quoted_string }
  rule(:double_quoted_string) {
    str('"') >> (
      str('"').absent? >> any
    ).repeat(1).as(:string) >> str('"')
  }
  rule(:single_quoted_string) {
    str("'") >> (
      str("'").absent? >> any
    ).repeat(1).as(:string) >> str("'")
  }

  # whitespace
  rule(:space) { match(/\s/).repeat(1) }
  rule(:space?) { match(/\s/).repeat(1).maybe }

  rule(:data_structure) { array | object | integer | string }

  root(:data_structure)
end

begin
  ap Mini.new.parse(string)
rescue Parslet::ParseFailed => failure
  puts failure.parse_failure_cause.ascii_tree
end