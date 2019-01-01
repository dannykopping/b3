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
    head:bitwise_array_element
    tail:(',' _ value:bitwise_array_element { return value; })*
      {
      return operator + "[" + [head].concat(tail).join(', ') + "]"; }
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
    tail:(',' _ value:object_property { return value; })* {
        var result = {};

        [head].concat(tail).forEach(function(element) {
          result[element.name] = element.value;
        });

        return result;
    })?
  '}'
  { return values !== null ? values : []; }

arguments_list
 = values:(
    head:data_structure
    tail:(',' _ value:data_structure { return value; })+
      { return [head].concat(tail); }
    )?
  { return values !== null ? values : []; }

data_structure
  = array / int / string / object / bitwise_array / flag / flags

int = [0-9]+ { return parseInt(text()); }

string = value:(single_quoted_string / double_quoted_string) { return value }

single_quoted_string = "'" value:([^']*) "'" { return value.join('') }
double_quoted_string = '"' value:([^"]*) '"' { return value.join('') }

object_property
  = ellipsis? _ key:([_a-zA-Z0-9'"]+) _ '=' _ value:(arithmetic_expression / data_structure) {
    return {name: key.join(''), value: value}
  }

arithmetic_expression = [-0-9]+ _ [+-/*] _ [-0-9]+

result = _ '=' _ value:([^<]+) _ { return value.join(''); }

timing = _ '<' value:([\.\-0-9]+) '>' _ { return Number(value.join('')); }

pid = ('[pid' _)? _ value:([0-9]+) _ (']')? _ { return Number(value.join('')); }

ellipsis = _ '...' _

_ 'whitespace' = [ \t\n\r]* { return '.' }