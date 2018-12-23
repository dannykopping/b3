require 'parslet'
require 'awesome_print'
include Parslet


#
#
# match strings in object that are not quoted (flags as separate datatype? are strings always quoted?)
#
#
#

string = <<-EOF
8, [9,10,100], {x='y'}, 0xdeadBEEF199
EOF

# string = '[  [       1],2 , "bob", ["another \'inner\' bob", \'rad "dude"\']  3, {hello=sally, bob= [1,2,3 ]  }    ]'

class Mini < Parslet::Parser
  # separators
  rule(:separator) { match(',') }
  rule(:separator?) { match(',').maybe }

  # arrays
  rule(:array) {
    str('[') >> (
      str('[').absent? >> array_element
    ).repeat(0).as(:elements) >> str(']')
  }
  rule(:array_element) { space? >> data_structure.as(:element) >> space? >> separator? }

  # objects
  rule(:object) {
    str('{') >> (
    str('{').absent? >> property
    ).repeat(0).as(:properties) >> str('}')
  }

  rule(:property_key) { match(/[a-zA-Z0-9_'"]/).repeat(1) }
  rule(:property_value) { data_structure.repeat(0) }
  rule(:property) { space? >> property_key.as(:key) >> space? >> str('=') >> space? >> property_value.as(:value) >> space? }

  # ints (match integers not followed by 'x' - for address)
  rule(:integer) { match('[0-9]').repeat(1).as(:integer) >> str('x').absent? }

  # addresses
  rule(:address) { (str('0x') >> match(/[0-9a-fA-F]/).repeat(1)).as(:address) }

  # strings
  rule(:string) { single_quoted_string | double_quoted_string }
  rule(:double_quoted_string) {
    str('"') >> (
      str('"').absent? >> any
    ).repeat(0).as(:string) >> str('"')
  }
  rule(:single_quoted_string) {
    str("'") >> (
      str("'").absent? >> any
    ).repeat(0).as(:string) >> str("'")
  }

  rule(:element_list) {
    array_element >> space? >> separator? >> space? >> array_element.maybe
  }

  # whitespace
  rule(:space) { match(/\s/).repeat(1) }
  rule(:space?) { match(/\s/).repeat(1).maybe }

  rule(:data_structure) { array | object | integer | string | address }

  rule(:argument_list) {
    data_structure >> space? >> separator? >> space? >> argument_list.maybe
  }

  root(:argument_list)
end

begin
  ap Mini.new.parse(string)
rescue Parslet::ParseFailed => failure
  puts failure.parse_failure_cause.ascii_tree
end