require 'parslet'

module B3
  class ArgumentsParser < Parslet::Parser
    root(:argument_list)

    rule(:argument_list) {
      data_structure >> space? >> separator? >> space? >> argument_list.repeat
    }

    rule(:data_structure) {
      array | bitwise_array | object | inline_object |
      integer | string | address | null | flag_list | comment | socket_notation
    }

    # whitespace
    rule(:space?) { match(/\s/).repeat }

    # separators
    rule(:separator) { match(',') }
    rule(:separator?) { match(',').maybe }

    # arrays
    rule(:array) {
      str('[') >> (
        str(']').absent? >> array_element
      ).repeat.as(:array_elements) >> str(']')
    }
    rule(:array_element) { space? >> data_structure.as(:array_element) >> space? >> separator? }

    # bitwise operator expression
    rule(:bitwise_array) {
      (str('~') | str('^')).as(:bitwise_operator) >>
      str('[') >> (
      str(']').absent? >> bitwise_array_element
      ).repeat.as(:array_elements) >> str(']')
    }
    rule(:bitwise_array_element) { space? >> flag_list.as(:array_element) >> space? }

    # strange socket notation
    rule(:socket_notation) {
      str('[') >> (
        match('[0-9]').repeat(1) >> space? >> str('->') >> space? >> match('[0-9]').repeat(1)
      ).as(:socket_notation) >> str(']')
    }

    # objects
    rule(:object) {
      str('{') >> (
        str('}').absent? >> property
      ).repeat.as(:properties) >> str('}')
    }

    rule(:inline_object) { # i.e. no enclosing {}
      property_definition.as(:inline_object)
    }

    rule(:property_key) { match(/[_a-zA-Z][_a-zA-Z0-9'"]*/).repeat(1) }
    rule(:property_value) { arithmetic_expression | data_structure }
    rule(:property_definition) {
      property_key.as(:key) >> space? >> str('=') >> space? >>
      property_value.as(:value)
    }
    rule(:property) {
      ellipsis | property_definition >> space? >> str(',').maybe >> property.repeat >> space?
    }

    # ints (match integers not followed by 'x' - for address)
    rule(:integer) { match(/-?[0-9]/).repeat(1).as(:integer) >> str('x').absent? }

    # addresses
    rule(:address) { (str('0x') >> match(/[0-9a-fA-F]/).repeat(1)).as(:address) }

    # strings
    rule(:string) { single_quoted_string | double_quoted_string }
    rule(:double_quoted_string) {
      str('@').maybe >> # in the case of socket address printing
      str('"') >> (
        str('\\').ignore >> str('"') |
        str('"').absent? >> any
      ).repeat.as(:string) >> str('"') >> space? >> ellipsis.maybe
    }
    rule(:single_quoted_string) {
      str("'") >> (
        str('\\').ignore >> str("'") |
        str("'").absent? >> any
      ).repeat.as(:string) >> str("'")
    }

    # flags/flags
    rule(:flags) { match(/[_A-Z0-9]/).repeat(1) >> str('|').maybe >> flags.repeat }
    rule(:flag_list) { flags.as(:flag_list) }

    # null
    rule(:null) { str('NULL').as(:null) }

    # comments
    rule(:comment) {
      space? >> str('/*') >> (
        str('*/').absent? >> any
      ).repeat >> str('*/')
    }

    rule(:arithmetic_expression) {
      match(/[0-9]/).repeat >> space? >>
        (str('+') | str('-') | str('*') | str('/')) >> space? >>
      match(/[0-9]/).repeat
    }

    # ellipsis
    rule(:ellipsis) { str('...') }

    def self.execute(arguments_str)
      arguments_str = arguments_str.to_s.strip.scrub
      return [] if arguments_str.empty?

      parsed = self.new.parse(arguments_str)
      transform_result(parsed)
    rescue Parslet::ParseFailed => e
      raise e
    end

    private

    def self.transform_result(parsed)
      transformed = Transformer.new.apply(parsed)

      # always return result as an array
      transformed = [transformed] unless transformed.is_a?(Array)
      transformed.freeze
    end
  end

  class Transformer < Parslet::Transform
    transform_object = lambda { |value|
      return {value[:key].to_sym => value[:value]} unless value.is_a?(Array)

      hash = {}
      value.map do |data|
        hash[data[:key].to_sym] = data[:value]
      end

      hash
    }

    rule(:integer => simple(:x))          { Integer(x) }
    rule(:string => simple(:x))           { x.to_s }
    rule(:flag_list => simple(:x))        { x.to_s.include?('|') ? x.to_s.split('|') : x.to_s }
    rule(:array_element => subtree(:x))   { x }
    rule(:array_elements => subtree(:x))  { x }
    rule(:bitwise_operator => simple(:op),
         :array_elements => subtree(:x))  { "#{op.to_s}#{x}" }
    rule(:address => simple(:x))          { x.to_s }
    rule(:null => simple(:x))             { nil }
    rule(:properties => subtree(:x))      { transform_object.call(x) }
    rule(:inline_object => subtree(:x))   { transform_object.call(x) }
    rule(:socket_notation=> simple(:x))   { "[#{x.to_s}]" }
  end
end