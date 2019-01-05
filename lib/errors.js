const NE = require('node-exceptions')

class UnfinishedSyscallException extends NE.LogicalException {}

module.exports = {
  UnfinishedSyscallException: UnfinishedSyscallException
}