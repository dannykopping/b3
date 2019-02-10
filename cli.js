#!/usr/bin/env node
// package deps
const program = require('commander'),
  fs = require("fs"),
  readline = require('readline'),
  peg = require('pegjs'),
  debug = require('debug')('b3');

// library deps
const parser = require('./lib/parser.js'),
  errors = require('./lib/errors.js'),
  package = require('./package.json');

program
  .version(package.version)
  .option('-s, --stop-on-fail', 'Stop on parser failure', false)
  .parse(process.argv);

const grammar = fs.readFileSync('grammar.pegjs', 'utf8');
const pegParser = peg.generate(grammar, {cache: true, optimize: 'speed'});

parser.initialize(pegParser);

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
  terminal: false
});

rl.on('line', parseLine);

function parseLine(line) {
  try {
    debug('Received line: ' + line);

    let parsed = parser.parseLine(line, {debug:true});
    console.log(outputLine(parsed));
  } catch(e) {
    switch(true) {
      case e instanceof errors.UnfinishedSyscallException:
        debug('Encountered partial syscall, skipping: ' + line);
        // suppress
        return;
    }

    debug('[PARSE ERROR] ' + e);
    if(program.stopOnFail) {
      console.error('[PARSE ERROR] ' + e);
      debug('Exiting due to stopOnFail argument');
      process.exit(1);
    }
  }
}

// TODO: some kind of buffering solution to boost performance?
function outputLine(line) {
  return JSON.stringify(line);
}