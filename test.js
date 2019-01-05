var parser = require('./lib/parser.js');
var errors = require('./lib/errors.js');
var readline = require('readline');

var rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
  terminal: false
});

rl.on('line', parseLine);
function parseLine(line) {
  try {
    console.log(line);
    console.log(JSON.stringify(parser.parse(line)));
  } catch(e) {
    console.log('ERROR!', e);
  }
}