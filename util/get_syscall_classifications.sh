#!/bin/bash

# clone strace repo from git clone https://github.com/strace/strace.git
# cd into directory

cd ~/Downloads/strace

echo '' > /tmp/syscalls

find -name 'syscallent.h' |
    while read file; do
        cat $file | cut -d',' -f2- | awk '{print $3, "," $1}' | sort >> /tmp/syscalls;
    done

# replace shorthand definitions with definitions found in sysent_shorthand_defs.h
cat /tmp/syscalls | sort | uniq | grep -E ^\" |
    sed 's/\bTD\b/TRACE_DESC/' |
    sed 's/\bTF\b/TRACE_FILE/' |
    sed 's/\bTI\b/TRACE_IPC/' |
    sed 's/\bTN\b/TRACE_NETWORK/' |
    sed 's/\bTP\b/TRACE_PROCESS/' |
    sed 's/\bTS\b/TRACE_SIGNAL/' |
    sed 's/\bTM\b/TRACE_MEMORY/' |
    sed 's/\bTST\b/TRACE_STAT/' |
    sed 's/\bTLST\b/TRACE_LSTAT/' |
    sed 's/\bTFST\b/TRACE_FSTAT/' |
    sed 's/\bTSTA\b/TRACE_STAT_LIKE/' |
    sed 's/\bTSF\b/TRACE_STATFS/' |
    sed 's/\bTFSF\b/TRACE_FSTATFS/' |
    sed 's/\bTSFA\b/TRACE_STATFS_LIKE/' |
    sed 's/\bPU\b/TRACE_PURE/' |
    sed 's/\bNF\b/SYSCALL_NEVER_FAILS/' |
    sed 's/\bMA\b/MAX_ARGS/' |
    sed 's/\bSI\b/MEMORY_MAPPING_CHANGE/' |
    sed 's/\bSE\b/STACKTRACE_CAPTURE_ON_ENTER/' |
    sed 's/\bCST\b/COMPAT_SYSCALL_TYPES/' |
    sed 's/,//g' |                                  # clear extraneous commas
    sed 's/|/,/g' |                                 # clear extraneous pipes, convert to commas
    sed -e 's/0$/KERNEL_PRIVATE/g' |                # replace "0" shorthand with KERNEL_PRIVATE
    grep -v '#' |                                   # clear syscalls containing "#" - maybe keep for Linux 32bit?
cat