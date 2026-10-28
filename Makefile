EMACS ?= emacs
PROFILER =
TAG =
ELFILES = $(filter-out evil-pkg.el evil-autoloads.el,$(wildcard evil*.el))
BATCH = $(EMACS) -Q --batch -L . -L test

.PHONY: all compile clean tests test emacs term terminal profiler

# Byte-compile Evil.
all: compile

compile:
	$(BATCH) -f batch-byte-compile $(ELFILES)

# Delete byte-compiled files etc.
clean:
	rm -f *.elc test/*.elc test-results.txt

# Run tests.
# The TAG variable may specify a test tag or a test name:
#       make test TAG=repeat
# This will only run tests pertaining to the repeat system.
test:
	rm -f test-results.txt
	$(BATCH) -l evil-tests --eval "(evil-tests-initialize '(${TAG}))"

# Byte-compile Evil and run all tests.
tests: compile
	$(MAKE) test; status=$$?; $(MAKE) clean; exit $$status

# Load Evil in a fresh instance of Emacs and run all tests.
emacs:
	$(EMACS) -Q -L . -L test -l evil-tests \
		--eval "(evil-mode 1)" \
		--eval "(evil-tests-initialize '(${TAG}) '(${PROFILER}) t)"

# Load Evil in a terminal Emacs and run all tests.
term terminal:
	$(EMACS) -nw -Q -L . -L test -l evil-tests \
		--eval "(evil-mode 1)" \
		--eval "(evil-tests-initialize '(${TAG}) '(${PROFILER}) t)"

# Run all tests with profiler.
profiler:
	$(BATCH) -l evil-tests --eval "(evil-mode 1)" \
		--eval "(evil-tests-initialize '(${TAG}) t)"
