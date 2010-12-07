# -*- makefile-gmake -*-

DOC_DIR=doc
VERSION=0.0.1
EBIN_DIR=./ebin

ifndef EJABBERD_DIR
EJABBERD_DIR=/usr/local/ejabberd/lib/ejabberd
endif
EJABBERD_EBIN_DIR=$(EJABBERD_DIR)/ebin
EJABBERD_INCLUDE_DIR=$(EJABBERD_DIR)/include
CANONICAL_RABBIT_HEADER=../rabbitmq-server/include/rabbit.hrl

WIDTH=1024
#WIDTH=800
DPI=$(shell echo '90 * $(WIDTH) / 1024' | bc)

ifeq ($(shell uname -s),Darwin)
SED=gsed
else
SED=sed
endif

EFLAGS= -pa $(EJABBERD_EBIN_DIR)
ifdef debug
  EFLAGS+=+debug_info +export_all
endif

ERL_OBJECTS=mod_rabbitmq_util_priv.beam mod_rabbitmq_util.beam mod_rabbitmq_consumer.beam mod_rabbitmq.beam

all: check_rabbit_hrl $(ERL_OBJECTS)

check_rabbit_hrl:
	@if [ -e $(CANONICAL_RABBIT_HEADER) ]; then diff -q $(CANONICAL_RABBIT_HEADER) src/rabbit.hrl; else echo Skipping rabbit.hrl check because $(CANONICAL_RABBIT_HEADER) does not exist; fi

clean:
	rm -rf $(EBIN_DIR)
	rm -f build-stamp install-stamp

clean-doc:
	rm -rf doc/*

doc:
	mkdir ./doc

.PHONY: documentation
documentation: \
		doc/overview.edoc \
		doc/xmpp-amqp-gateway.png \
		doc/whole-network-1.png \
		doc/whole-network-2.png
	$(MAKE) doc
	erl -noshell \
		-eval 'edoc:application(mod_rabbitmq, ".", [])' \
		-run init stop
	$(SED) -e 's:\(<p><i>Generated by EDoc\), .*\(</i></p>\):\1\2:' -i doc/*.html

doc/overview.edoc: src/overview.edoc.in
	$(MAKE) doc
	$(SED) -e 's:%%VERSION%%:$(VERSION):g' < $< > $@

doc/%.png: src/%.svg
	inkscape --export-dpi=$(DPI) --export-png=$@ $<

%.beam: src/%.erl
	erlc $(EFLAGS) -I $(EJABBERD_INCLUDE_DIR) $<
	mkdir -p $(EBIN_DIR)
	mv $@ $(EBIN_DIR)

distclean: clean
