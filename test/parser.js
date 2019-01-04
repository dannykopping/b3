var expect = require('expect.js');
var parser = require('../lib/parser.js');

var options = {
  debug: process.env.DEBUG == 'true'
};

describe('strace output parsing', function() {
  describe('basic functionality', function() {
    let basic_line = String.raw `write(26, "hello world\n", 12) = 12 <0.000021>`;
    
    it('accurately parses a given line', function() {
      expect(parser.parseLine(basic_line, options)).to.eql({
        pid: null,
        syscall: 'write',
        args: [
          26,
          String.raw `hello world\n`,
          12
        ],
        result: 12,
        timing: 0.000021
      })
    });

    // maybe turn this into json-schema or something similar
    it('accurately coerces values into appropriate data type', function() {
      const parsed = parser.parseLine(basic_line, options);
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
          String.raw `hello world\n`,
          12
        ],
        result: 12,
        timing: 0.000021
      };

      expect(parser.parseLine(String.raw `[pid 10757] ${basic_line}`, options)).to.eql(result);
      expect(parser.parseLine(String.raw `10757 ${basic_line}`, options)).to.eql(result);
    });

    it('accurately parses a syscall with no arguments', function() {
      expect(parser.parseLine(String.raw `getuid() = 1000 <0.000007>`, options)).to.eql({
        pid: null,
        syscall: 'getuid',
        args: [],
        result: 1000,
        timing: 0.000007
      });
    });

    it('accurately parses a syscall with no timing data', function() {
      expect(parser.parseLine(String.raw `getuid() = 1000`, options)).to.eql({
        pid: null,
        syscall: 'getuid',
        args: [],
        result: 1000,
        timing: null
      });
    });

    it('refuses to parse unfinished syscalls', function() {
      expect(function() {
        parser.parseLine(String.raw `6955  <... futex resumed> )             = -1 ETIMEDOUT (Connection timed out)`, options)
      }).to.throwException('Unfinished/resume line encountered');

      expect(function (){
        try {
          parser.parseLine(String.raw`7016  futex(0x7ff23c537108, FUTEX_WAIT_PRIVATE, 0, {tv_sec=0, tv_nsec=12399422} <unfinished ...>`, options).to.eql(null);s
        } catch(e) {}
      })
    });

    it('fails silently if debug mode is disable and given line is invalid', function() {
      expect(parser.parseLine(String.raw `...invalid...`, {debug:false})).to.eql(null);
    });

    it('throws an exception if debug mode is enabled and given line is invalid', function() {
      expect(function() {
        parser.parseLine(String.raw `...invalid...`, {debug:true})
      }).to.throwException();
    });

    it('returns null for an empty line', function() {
      expect(parser.parseLine('', options)).to.equal(null);
      expect(parser.parseLine('    ', options)).to.equal(null);
      expect(parser.parseLine(null, options)).to.equal(null);
    });

    it('handles values in arguments which might confuse the parser', function() {
      expect(parser.parseLine(String.raw `[pid 31112] read(10, "something) ="..., 8192) = 8192 <0.000010>`, options)).to.eql({
        pid: 31112,
        syscall: 'read',
        args: [10, 'something) =', 8192],
        result: 8192,
        timing: 0.000010
      });
    });

    it('handles strace errors gracefully', function() {
      expect(function() {
        parser.parseLine(String.raw `strace: attach: ptrace(PTRACE_SEIZE, 1): Operation not permitted`, options)
      }).to.throwException('Strace error!');
    });
  });

  describe('argument parsing', function() {
    it('should handle syscalls with simple string arguments', function() {
      expect(parser.parseLine(String.raw `read(10, "1234567890", 10) = 10`, options)).to.eql({
        pid: null,
        syscall: 'read',
        args: [10, '1234567890', 10],
        result: 10,
        timing: null,
      });
    });

    it('should handle syscalls with string arguments with inner quotes', function() {
      expect(parser.parseLine(String.raw `read(10, "123'45'6\"7\"890", 10) = 10`, options)).to.eql({
        pid: null,
        syscall: 'read',
        args: [10, '123\'45\'6\"7\"890', 10],
        result: 10,
        timing: null,
      });
    });

    it('should handle syscalls with complex string arguments', function() {
      // write(1, "i'm a string with \"different\" kinds of quotes (even \342\200\230non-ascii\342\200\231)", "another 'value\""

      line = String.raw `write(3, "invalid: \255\nkanji: \346\274\242\345\255\227", 24) = 24`;
      expect(parser.parseLine(line, options)).to.eql({
        pid: null,
        syscall: 'write',
        args: [3, String.raw `invalid: \255\nkanji: \346\274\242\345\255\227`, 24],
        result: 24,
        timing: null,
      });
    });
  });
});