line
  = pid:pid? syscall:syscall '(' _ args:arguments_list _ ')' result:result timing:timing? {
    return {
        syscall: syscall,
        args: args,
        result: result,
        timing: timing,
        pid: pid
    }
  }

syscall
  = _ value:([_a-zA-Z0-9'"]+) { return value.join(''); }

array
  = '['
  values:(
    head:data_structure
    tail:(',' _ value:data_structure { return value; })*
      { return [head].concat(tail); }
    )?
  ']'
  { return values !== null ? values : []; }

bitwise_array
  = values:(
    operator:([~^]) '['
    head:(value:bitwise_array_element { return value.join(''); })
    tail:(',' _ value:bitwise_array_element { return value.join(''); })*
      {
        return {
          operator:operator,
          elements: [head].concat(tail)
        };
      }
    )?
  ']'
  { return values !== null ? values : []; }

bitwise_array_element
  = _ array_elements:flags _ { return array_elements; }

flag = _ value:[_A-Z0-9]+ _ { return value.join(''); }

flags
  = values:(
    head:flag
    tail:('|' _ value:flag { return value; })*
      { return [head].concat(tail); }
    )?
  { return values !== null ? values : []; }

object
  = '{'
  values:(
    head:object_property
    tail:(',' _ value:ellipsis? / value:object_property { return value; })* {
        var result = {};

        [head].concat(tail).forEach(function(element) {
          if(!element.hasOwnProperty('name') || !element.hasOwnProperty('value')) {
            return;
          }
          result[element.name] = element.value;
        });

        return result;
    })?
  '}'
  { return values !== null ? values : []; }

arguments_list
 = values:(
    head:data_structure
    tail:("," _ value:data_structure { return value; })*
      { return [head].concat(tail); }
    )?
  {
    return values !== null ? values : [];
  }

data_structure
  = array / object / bitwise_array / address / int / string / null / flags / flag

int = [-0-9]+ { return parseInt(text()); }

address = '0x' value:([0-9a-fA-F]*) { return parseInt(value.join(''), 16) }

null = _ "NULL" _ { return null; }

// string processing borrowed from https://github.com/pegjs/pegjs/blob/master/examples/json.pegjs
string "string"
  = _ quotation_mark chars:char* quotation_mark ellipsis? { return chars.join(""); }

char
  = unescaped
  / escape
    sequence:(
        '"'
      /  "'"
      / "\\"
      / "/"
      / digits:DIGIT+ { return ["\\"].concat(digits).join('') }
      / "b" { return "\\b"; }
      / "f" { return "\\f"; }
      / "n" { return "\\n"; }
      / "r" { return "\\r"; }
      / "t" { return "\\t"; }
      / "u" digits:$(HEXDIG HEXDIG HEXDIG HEXDIG) {
          return String.fromCharCode(parseInt(digits, 16));
        }
    )
    { return sequence; }

escape
  = "\\"

quotation_mark
  = '"' / '"'

unescaped
  = [^\0-\x1F\x22\x5C]

// ----- Core ABNF Rules -----

// See RFC 4234, Appendix B (http://tools.ietf.org/html/rfc4234).
DIGIT  = [0-9]
HEXDIG = [0-9a-f]i

basic_value = value:([_a-zA-Z0-9|]+) { return value.join(''); }
quoted_value = value:string { return value; }
function_call
  = values:(
  		head:(quoted_value / basic_value) _ "(" (quoted_value / basic_value)
        tail:(',' _ (quoted_value / basic_value))*
        ")"?
    ) {
    return text()
    }

object_property = key:key _ ("=")? _ value:(function_call / quoted_value / basic_value / null / flags)? {
  if(value !== null && value !== '') {
    return {name: key, value: value}
  }

  return {name: key, value: key};
}

key = value:basic_value { return value; }

arithmetic_expression = [-0-9]+ _ [+-/*] _ [-0-9]+

result
  = _ '=' _ value:([^<]+) _ {
    value = value.join('').trim();
    try {
        var numeric = Number(value);
        if(numeric.isNaN()) {
            return value;
        }

        return numeric;
    } catch(e) {
        return value;
    }
  }

timing = _ '<' value:([\.\-0-9]+) '>' _ { return Number(value.join('')); }

pid = ('[pid' _)? _ value:([0-9]+) _ (']')? _ { return Number(value.join('')); }

ellipsis = _ '...' _

_ 'whitespace' = [ \t\n\r]* { return '.' }