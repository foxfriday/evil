EMACS ?= emacs
PROFILER =
TAG =
EASK ?= eask

.PHONY: all compile clean tests test emacs term terminal profiler indent

# Byte-compile Evil.
all: compile

compile:
	$(EASK) compile

# Delete byte-compiled files etc.
clean:
	$(EASK) clean all

# Run tests.
# The TAG variable may specify a test tag or a test name:
#       make test TAG=repeat
# This will only run tests pertaining to the repeat system.
test:
	$(EASK) run command test

# Byte-compile Evil and run all tests.
tests: compile
	$(EASK) run command test
	$(EASK) clean elc
	rm -f .depend

# Load Evil in a fresh instance of Emacs and run all tests.
emacs:
	$(EMACS) -Q -L . -L test -l evil-tests \
		--eval "(evil-mode 1)" \
		--eval "(evil-tests-initialize '(${TAG}) '(${PROFILER}) t)"

# Load Evil in a terminal Emacs and run all tests.
term terminal:
	$(EASK) run command terminal

# Run all tests with profiler.
profiler:
	$(EASK) run command profiler

# Re-indent all Evil code.
# Loads Evil into memory in order to indent macros properly.
# Also removes trailing whitespace, tabs and extraneous blank lines.
indent: clean
	$(EASK) run command indent

