var expect = require('expect.js');
var parser = require('../lib/parser.js');

describe('strace output parsing', function() {
  describe('basic functionality', function() {
    let basic_line = 'write(26, "hello world\n", 12) = 12 <0.000021>';
    
    it('accurately parses a given line', function() {
      expect(parser.parseLine(basic_line)).to.eql({
        pid: null,
        syscall: 'write',
        args: [
          26,
          "hello world\n",
          12
        ],
        result: 12,
        timing: 0.000021
      })
    });

    // maybe turn this into json-schema or something similar
    it('accurately coerces values into appropriate data type', function() {
      const parsed = parser.parseLine(basic_line);
      expect(typeof parsed.pid == 'number' || parsed.pid == null).to.be.true;
      expect(parsed.syscall).to.be.a('string');
      expect(parsed.args).to.be.an('array');
      expect(typeof parsed.result == 'string' || typeof parsed.result == 'number').to.be.true;
      expect(parsed.timing).to.be.a('number');
    });

    it('accurately parses a given line with a PID', function() {
      const result = {
        pid: 10757,
          syscall: 'write',
        args: [
          26,
          "hello world\n",
          12
        ],
        result: 12,
        timing: 0.000021
      };

      expect(parser.parseLine(`[pid 10757] ${basic_line}`)).to.eql(result);
      expect(parser.parseLine(`10757 ${basic_line}`)).to.eql(result);
    });

    it('accurately parses a syscall with no arguments', function() {
      expect(parser.parseLine('getuid() = 1000 <0.000007>')).to.eql({
        pid: null,
        syscall: 'getuid',
        args: [],
        result: 1000,
        timing: 0.000007
      });
    });

    it('accurately parses a syscall with no timing data', function() {
      expect(parser.parseLine('getuid() = 1000')).to.eql({
        pid: null,
        syscall: 'getuid',
        args: [],
        result: 1000,
        timing: null
      });
    });

    it('refuses to parse unfinished syscalls', function() {
      expect(parser.parseLine('6955  <... futex resumed> )             = -1 ETIMEDOUT (Connection timed out)')).to.eql(null);
      expect(parser.parseLine('7016  futex(0x7ff23c537108, FUTEX_WAIT_PRIVATE, 0, {tv_sec=0, tv_nsec=12399422} <unfinished ...>')).to.eql(null);
    });

    it('fails silently if debug mode is disable and given line is invalid', function() {
      expect(parser.parseLine('...invalid...')).to.eql(null);
    });

    it('throws an exception if debug mode is enabled and given line is invalid', function() {
      expect(function() {
        parser.parseLine('...invalid...', {debug: true})
      }).to.throwException();
    });
  });
});