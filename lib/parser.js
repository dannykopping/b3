var errors = require('./errors');
var parser = require('../strace-parser');

const SYSCALL_TYPE = 'SYSCALL';
const ALERT_TYPE = 'ALERT';
const ERROR_TYPE = 'ERROR';

module.exports = {
  syscallType: SYSCALL_TYPE,
  alertType: ALERT_TYPE,
  errorType: ERROR_TYPE,

  parseLine: function(line, options={}) {
    const debug = options.hasOwnProperty('debug') && options.debug == true;
    const trace = options.hasOwnProperty('trace') && options.trace == true;

    try {
      if(line == null || line.trim().length <= 0) {
        return null;
      }

      // this will match lines that are marked as "unfinished" or "resume"
      if(line.match(/<\.\.\./) || line.match(/\.\.\.>/)) {
        throw new errors.UnfinishedSyscallException('Unfinished/resume line encountered');
      }

      return parser.parse(line);
    } catch(e) {
      if(trace) {
        console.log(e);
      }

      if(debug) {
        throw e;
      }

      return null;
    }
  }
};