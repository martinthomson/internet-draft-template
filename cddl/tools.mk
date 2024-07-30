# cddl and curl are prerequisite
# fail hard if they are not found

cddl ?= $(shell command -v cddl)
ifeq ($(strip $(cddl)),)
$(error cddl not found. To install cddl: 'gem install cddl')
endif

curl ?= $(shell command -v curl)
ifeq ($(strip $(curl)),)
$(error curl not found)
endif

diag2diag ?= $(shell command -v diag2diag.rb)
ifeq ($(strip $(diag2diag)),)
$(error diag2diag.rb not found. To install diag2diag.rb: 'gem install cbor-diag')
endif

diag2cbor ?= $(shell command -v diag2cbor.rb)
ifeq ($(strip $(diag2cbor)),)
$(error diag2cbor.rb not found. To install diag2cbor.rb: 'gem install cbor-diag')
endif

cbor2pretty ?= $(shell command -v cbor2pretty.rb)
ifeq ($(strip $(cbor2pretty)),)
$(error cbor2pretty.rb not found. To install cbor2pretty.rb: 'gem install cbor-diag')
endif
