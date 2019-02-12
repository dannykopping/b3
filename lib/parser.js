const errors = require('./errors'),
  fs = require("fs"),
  peg = require('pegjs'),
  tracer = require('pegjs-backtrace'),
  util = require('util'),
  debug = require('debug')('b3');

const SYSCALL_TYPE = 'SYSCALL';
const ALERT_TYPE = 'ALERT';
const ERROR_TYPE = 'ERROR';
const STOPPED_TYPE = 'STOPPED';

module.exports = {
  syscallType: SYSCALL_TYPE,
  alertType: ALERT_TYPE,
  errorType: ERROR_TYPE,
  stoppedType: STOPPED_TYPE,

  initialize: function(options={}) {
    let grammar = fs.readFileSync(__dirname + '/../grammar.pegjs', 'utf8');

    this.trace = options.hasOwnProperty('trace') && options.trace == true;
    this.parser = peg.generate(grammar, {cache: true, optimize: 'speed', trace: this.trace});
  },

  parseLine: function(line) {
    if(line == null || line.trim().length <= 0) {
      return null;
    }

    // this will match lines that are marked as "unfinished" or "resume"
    if(line.match(/<\.\.\./) || line.match(/\.\.\.>/)) {
      throw new errors.UnfinishedSyscallException('Unfinished/resume line encountered');
    }

    try {
      return this.parser.parse(line, {tracer: this.getTracer(line)});
    } catch(e) {
      debug("Exception caught");
      debug(util.format(e));

      throw e;
    }
  },

  getTracer: function(line) {
    if(!this.trace) {
      return null;
    }

    return new tracer(line, {showTrace: true});
  }
};
