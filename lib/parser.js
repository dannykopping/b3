var parser = require('../strace-parser');

module.exports = {
  parseLine: function(line) {
    // this will match lines that are marked as "unfinished" or "resume"
    if(line.match(/(<|>)?\.\.\.(<|>)?/)) {
      return null;
    }

    return parser.parse(line);
  }
}