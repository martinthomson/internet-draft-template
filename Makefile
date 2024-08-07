LIBDIR := lib
include $(LIBDIR)/main.mk

$(LIBDIR)/main.mk:
ifneq (,$(shell grep "path *= *$(LIBDIR)" .gitmodules 2>/dev/null))
	git submodule sync
	git submodule update $(CLONE_ARGS) --init
else
	git clone -q --depth 10 $(CLONE_ARGS) \
	    -b main https://github.com/martinthomson/i-d-template $(LIBDIR)
endif

include cddl/corim-frags.mk

define cddl_targets

$(drafts_xml):: cddl/$(1)-autogen.cddl

cddl/$(1)-autogen.cddl: $(addprefix cddl/,$(2))
	$(MAKE) -C cddl check-$(1)
	$(MAKE) -C cddl check-$(1)-examples

endef # cddl_targets

$(eval $(call cddl_targets,corim,$(CORIM_FRAGS)))

clean:: ; $(MAKE) -C cddl clean
