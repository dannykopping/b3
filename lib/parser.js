var parser = require('../strace-parser');

module.exports = {
  parseLine: function(line, options={}) {
    const debug = options.hasOwnProperty('debug') && options.debug == true;

    try {
      if(line == null || line.trim().length <= 0) {
        return null;
      }

      if(line.indexOf('strace:') == 0) {
        throw new Error(`Strace error! ${line}`);
      }

      // this will match lines that are marked as "unfinished" or "resume"
      if(line.match(/<\.\.\./) || line.match(/\.\.\.>/)) {
        throw new Error('Unfinished/resume line encountered');
      }

      return parser.parse(line);
    } catch(e) {
      if(debug) {
        throw e;
      }

      return null;
    }
  }
}