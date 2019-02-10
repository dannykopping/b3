line
  = error_line / alert_line / stopped_line / syscall_line

// add one for strace error

error_line
  = error:error {
      return {
        error: error,
        type: 'ERROR'
      }
    }

alert_line
  = pid:pid? alert:alert {
      return {
        pid: pid,
        alert: alert,
        type: 'ALERT'
      }
    }

stopped_line
  = pid:pid? notice:stop_notice {
      return {
        pid: pid,
        alert: notice,
        type: 'STOPPED'
      }
    }

syscall_line
  = pid:pid?
    syscall:syscall args:arguments_list result:result timing:timing? {
    return {
        syscall: syscall,
        args: args,
        result: result,
        timing: timing,
        pid: pid,
        type: 'SYSCALL'
    }
  }

syscall
  = _ value:([_a-zA-Z0-9'"]+) { return value.join(''); }

data_structure
  = socket_address_length_enclosed / socket_address_length /
    array /
    nested_struct / struct / pseudo_struct /
    bitwise_array /
    address /
    socket /
    int /
    string /
    struct_property /
    null /
    flags_alternate / flags / flag

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

flags_alternate
  = operator:([~^])? '['
  values:(
    head:flag
    tail:(_ value:flag { return value; })*
      {
        var elements = [head].concat(tail);

        if(operator) {
          return {
            operator: operator,
            elements: elements
          }
        }

        return elements;
      }
    )?
  ']'
  { return values !== null ? values : []; }

nested_struct
  = '{'
    values:(
      head:struct
      tail:(',' _ value:data_structure { return value })? {
        return [head].concat([tail]);
      }
    )?
  '}' {
    return values;
  }

struct
  = '{'
  values:(
    head:struct_property
    tail:(',' _ value:ellipsis? / value:struct_property { return value; })* {
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

struct_property
  = key:(key / capitalised_key) _ ("=")? _ value:(function_call / quoted_value / data_structure / basic_value)? {
      if(typeof value !== 'undefined' && value !== '') {
        return {name: key, value: value}
      }

      return {name: key, value: key};
    }

// separated by spaces, not commas - very strange
pseudo_struct
  = '{' value:[^\}]+ '}' {
  return value.join('').split(/\s+/)
}

key "key"
  = value:[_a-z0-9]+ { return value.join(''); }

capitalised_key "capitalised key"
  = value:([A-Z][_a-z0-9])+ {
      var flattened = [].concat.apply([], value);
      return flattened.join('');
    }

arguments_list
  = '(' _ values:(
    head:data_structure
    tail:("," _ value:(arguments_list_abbreviation / data_structure) { return value; })*
      {
        // if both the head and tail are empty arrays, don't return an array in an array
        if ((tail === null || tail.length <= 0) && (head === null || head.length <= 0)) {
          return [];
        }

        return [head].concat(tail);
      }
    )?
    _ arguments_list_abbreviation? _ ')'
  {
    return values !== null ? values : [];
  }

arguments_list_abbreviation
  = ("/*" _ [0-9]+ _ ("vars" / "entries") _ "*/") { return '...'; }

int = [-0-9]+ { return parseInt(text()); }

address = '0x' value:([0-9a-fA-F]*) { return parseInt(value.join(''), 16) }

null = _ "NULL" _ { return null; }

// string processing borrowed from https://github.com/pegjs/pegjs/blob/master/examples/json.pegjs
string "string"
  = _ quotation_mark chars:char* quotation_mark ellipsis? { return chars.join(""); }

socket
  = "@" path:string { return path }

socket_address_length_enclosed
  = "[" data:socket_address_length "]" { return data }

socket_address_length
  = ulen:([0-9]+) "->" rlen:([0-9]+) {
    return {
      ulen: parseInt(ulen.join('')),
      rlen: parseInt(rlen.join(''))
    }
  }

char
  = unescaped
  / escape
    sequence:(
        '"'
      /  "'"
      / "\\"
      / "/"
      / digits:digit+ { return ["\\"].concat(digits).join('') }
      / value:[a-zA-Z] { return "\\" + value }
    )
    { return sequence; }

escape
  = "\\"

quotation_mark
  = '"' / '"'

unescaped
  = [^\0-\x1F\x22\x5C]

digit  = [0-9]
hex_digit = [0-9a-f]i

// unquoted values should either start with a lowercase letter or number, or else be considered a flag
basic_value
  = value:([_a-z0-9][_a-zA-Z0-9]+) {
      var flattened = [].concat.apply([], value);
      return flattened.join('');
    }
quoted_value = value:string { return value; }
function_call
  = values:(
  		head:(quoted_value / basic_value) _ "(" (quoted_value / basic_value)
        tail:([^\)])*
        ")"?
    ) {
    return text()
    }

arithmetic_expression = [-0-9]+ _ [+-/*] _ [-0-9]+

result
  = _ '=' _ value:([^<]+) _ {
    value = value.join('').trim();
    try {
        var numeric = Number(value);
        if(isNaN(numeric)) {
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

alert = "+++" _ message:[^\+]+ _ "+++" { return message.join('').trim() }

stop_notice = "---" _ signal:flag _ data:data_structure _ "---" { return { signal: signal, data: data } }

error = "strace:" _ error:(.+) { return error.join('').trim() }

_ 'whitespace' = [ \t\n\r]* { return undefined }
