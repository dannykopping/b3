# B3 [![CircleCI](https://img.shields.io/circleci/project/github/dannykopping/b3/master.svg?logo=b3&style=flat)](https://circleci.com/gh/dannykopping/b3/tree/master)

## Purpose

This project's goal is to parse the famously impenetrable `strace` output into JSON.

## Demo

[![asciicast](https://asciinema.org/a/226608.svg)](https://asciinema.org/a/226608)

## Installation

Using **npm**: `npm i -g b3-strace-parser`

or download the [latest release](https://github.com/dannykopping/b3/releases)

## Usage

```bash
strace -f -p 1234 |& b3
# The "|&" is a shortcut for "2>&1 |" from Bash 4.0 (pipe stdout AND stderr to next program)
```

`strace` outputs to `stderr`, which is why you need the redirection.

For extra tastiness, combine with [`jq`](https://stedolan.github.io/jq/)

```bash
strace -f -p 1234 |& b3 | jq '' -c
```

### Tests

Run `npm test` to execute the test suite.

To enable extra tracing for problem-solving, set `TRACE=true`

### Caveats, Limitations & Other Miscellany

 - Speed-wise, the utility performs well (according to my biased and unscientific benchmarking). It can currently parse ~15-20k lines per second, and there's much room for optimisation I'm sure.
 - The utility cannot handle [unfinished syscalls](http://www.man7.org/linux/man-pages/man1/strace.1.html#DESCRIPTION)
 - The utility silently skips parsers, unless the `-s/--stop-on-fail` switch is enabled
 - The utility uses the very excellent [peg.js](https://pegjs.org/) and you should too!
 
If you encounter any parsing errors, please create an issue and I will be happy to fix it! ...or better yet, be a good FOSS citizen and send an MR :)

### Um, why?

Well, that's up to you. I figured that this output is so information-dense that it has to be useful in a structured format.

I love this utility and use it all the time, and wanted to learn more about it.

...plus it was a fun, terrifying, frustrating and illuminating excursion into parsing grammars (but _oy vey what a schlep!_).

### Why not do this in C?

  1. I don't know C well enough, and...
  2. I invite you to examine the [glorious mess](https://github.com/strace/strace/search?q=tprintf&unscoped_q=tprintf) that is this nearly 30-year old edifice
  3. Many people have [tried and failed/given up](https://www.mail-archive.com/search?l=strace-devel%40lists.sourceforge.net&q=json&submit.x=0&submit.y=0), and I'm neither smarter nor more persistent than them