line
  = syscall:syscall '(' _ args:arguments_list _ ')' _ '= 0' {
  return [syscall, args]
}

syscall
  = _ (([_a-zA-Z][_a-zA-Z0-9'"]*)+) { return text(); }

arguments_list
  = value:data_structure _ ','? _ { return value }

array = '['
values:(
  head:data_structure
tail:(',' _ value:data_structure { return value; })*
{ return [head].concat(tail); }
)?
  ']'
  { return values !== null ? values : []; }

data_structure
  = array / int / string

int = [0-9] { return parseInt(text()); }

string = value:(single_quoted_string / double_quoted_string) { return value }

single_quoted_string = "'" value:[^']* "'" { return value }
double_quoted_string = '"' value:[^"]* '"' { return value }

_ 'whitespace' = [ \t\n\r]* { return '.' }