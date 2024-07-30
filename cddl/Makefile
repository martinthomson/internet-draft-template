.DEFAULT_GOAL := check

SHELL := /bin/bash

include tools.mk

%.cbor: %.diag
	$(diag2cbor) $< > $@

check:: cbor-tags-unique
check:: check-corim check-corim-examples

# $1: label
# $2: cddl fragments
# $3: diag test files
define cddl_check_template

check-$(1): $(1)-autogen.cddl
	$$(cddl) $$< g 1 | $$(diag2diag) -e

.PHONY: check-$(1)

$(1)-autogen.cddl: $(2)
	for f in $$^ ; do ( grep -v '^;' $$$$f ; echo ) ; done > $$@

CLEANFILES += $(1)-autogen.cddl

check-$(1)-examples: $(1)-autogen.cddl $(3:.diag=.cbor)
	@for f in $(3:.diag=.cbor); do \
		echo ">> validating $$$$f against $$<" ; \
		$$(cddl) $$< validate $$$$f &>/dev/null || exit 1 ; \
		echo ">> saving prettified CBOR to $$$${f%.cbor}.pretty" ; \
		$$(cbor2pretty) $$$$f > $$$${f%.cbor}.pretty ; \
	done

.PHONY: check-$(1)-examples

CLEANFILES += $(3:.diag=.cbor)
CLEANFILES += $(3:.diag=.pretty)

endef # cddl_check_template

include corim-frags.mk

$(eval $(call cddl_check_template,corim,$(CORIM_FRAGS),$(CORIM_EXAMPLES)))

clean: ; rm -f $(CLEANFILES)

# Extract the CBOR tags defined by CoRIM (i.e., those in the 5xx space)
cbor-tags.txt: $(wildcard *.cddl) ; grep -h '#6\.5' *cddl | sort -u -t'=' -k2 > $@

# Return an error if there are duplicate CBOR Tags defined
cbor-tags-unique: cbor-tags.txt
	@echo -n "duplicated CBOR tag(s): "
	@if grep -E -h -o '#6\.[0-9]{3}' $< | uniq -d | grep . -c ; \
	then \
		echo "check the following:" ; \
		grep -E -h -o '#6\.[0-9]{3}' $< | uniq -d ; \
	fi
