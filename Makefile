.PHONY: resetdb models

include build/makefiles/shellvars.mk
include build/makefiles/osvars.mk

all: services models

clean: clean_services clean_models
distclean: clean_services clean_models clean_db clean_setup clean_vendor

#
# Services: protobuf based service builds. Typically just add to SERVICES var.
#

SERVICES := coin pot

PROTOBUF_PB_FILES := $(SERVICES:%=rpc/go/%/service.pb.go)
PROTOBUF_TWIRP_FILES := $(SERVICES:%=rpc/go/%/service.twirp.go)
PROTOBUF_VALIDATOR_FILES := $(SERVICES:%=rpc/go/%/service.validator.pb.go)
PROTOBUF_PYTHON_FILES := $(SERVICES:%=rpc/python/%/service_pb2.py)
PROTOBUF_PYTHON_TWIRP_FILES := $(SERVICES:%=rpc/python/%/service_pb2_twirp.py)
PROTOBUF_JS_FILES := $(SERVICES:%=rpc/js/%/service_pb.js)
PROTOBUF_JS_TWIRP_FILES := $(SERVICES:%=rpc/js/%/service_pb_twirp.js)
SWAGGER_JSON_FILES := $(SERVICES:%=swaggerui/rpc/%/service.swagger.json)
PROTOBUF_ALL_FILES := $(PROTOBUF_PB_FILES) $(PROTOBUF_TWIRP_FILES) $(PROTOBUF_VALIDATOR_FILES) \
                      $(PROTOBUF_PYTHON_FILES) $(PROTOBUF_PYTHON_TWIRP_FILES) \
                      $(PROTOBUF_JS_FILES) $(PROTOBUF_JS_TWIRP_FILES) \
                      $(SWAGGER_JSON_FILES)
STATIK = $(_TOOLS_BIN)/statik

# Everything we build from a proto def
rpc/go/%/service.twirp.go \
rpc/go/%/service.pb.go \
rpc/go/%/service.validator.pb.go \
rpc/python/%/service_pb2.py \
rpc/python/%/service_pb2_twirp.py \
rpc/js/%/service_pb.js \
rpc/js/%/service_pb_twirp.js \
swaggerui/rpc/%/service.swagger.json \
  : proto/%/service.proto
	PATH="$(_TOOLS_BIN):$$PATH" $(PROTOC) \
            --proto_path=./proto \
            --proto_path=./vendor \
            --proto_path=./vendor/github.com/grpc-ecosystem/grpc-gateway \
            --twirp_out=./rpc/go \
            --go_out=./rpc/go \
            --govalidators_out=./rpc/go \
            --python_out=./rpc/python \
            --twirp_python_out=./rpc/python \
            --js_out=import_style=commonjs,binary:./rpc/js \
            --twirp_js_out=import_style=commonjs,binary:./rpc/js \
            --twirp_swagger_out=./swaggerui/rpc \
            $<

services: proto swagger

proto: $(PROTOBUF_ALL_FILES)

$(PROTOBUF_PB_FILES) $(PROTOBUF_TWIRP_FILES) $(PROTOBUF_VALIDATOR_FILES): rpc/go rpc/python rpc/js swaggerui/rpc

rpc/go rpc/python rpc/js swaggerui/rpc:
	mkdir -v -p $@

swagger: swaggerui-statik/statik/statik.go

swaggerui-statik/statik/statik.go: swaggerui/index.html $(SWAGGER_JSON_FILES)
	$(STATIK) -f -src=swaggerui -dest=swaggerui-statik

clean_services:
	rm -vf $(PROTOBUF_ALL_FILES)
	rm -rf rpc swaggerui/rpc


#
# Models: xo generated from working schema and query defs
#

MODEL_PATH := internal/models
TEMPLATE_PATH := sql/templates
XO = PATH="$(_TOOLS_BIN):$$PATH" $(_TOOLS_BIN)/xo
USQL = $(_TOOLS_BIN)/usql

db: database.sqlite3

database.sqlite3:
	source sql/config && $(USQL) $$DB -f sql/schema.sqlite3.sql

models:
	mkdir -v -p internal/models
	source sql/config && $(XO) $$DB --int32-type int32 -o $(MODEL_PATH) --template-path $(TEMPLATE_PATH)
	source sql/config && $(XO) $$DB --int32-type int32 -o $(MODEL_PATH) --query-mode --query-type PotsPaged --query-trim < sql/pots_paged.query.sql
	source sql/config && $(XO) $$DB --int32-type int32 -o $(MODEL_PATH) --query-mode --query-type CoinsInPot --query-trim < sql/coins_in_pot.query.sql

resetdb: clean_db clean_models db

clean_models:
	rm -vf internal/models/*.xo.go

clean_db:
	rm -vf database.sqlite3



#
# Setup: protoc+plugins, other tools
#
# Note that go mod vendor will bring down *versioned* tools base on go.mod. Yay.
# We use depends/*.go to trick go mod into getting our tools for local builds.
#

# protoc
PROTOC_VERSION := 3.7.1
PROTOC_RELEASES_PATH := https://github.com/protocolbuffers/protobuf/releases/download
PROTOC_ZIP := protoc-$(PROTOC_VERSION)-$(PROTOC_PLATFORM).zip
PROTOC_DOWNLOAD := $(PROTOC_RELEASES_PATH)/v$(PROTOC_VERSION)/$(PROTOC_ZIP)
_TOOLS_DIR := ./_tools
_TOOLS_BIN := $(_TOOLS_DIR)/bin
PROTOC := $(_TOOLS_BIN)/protoc

$(_TOOLS_BIN)/%:
	cd $< && GOBIN=$(PWD)/$(_TOOLS_BIN) go install

setup: setup_vendor $(_TOOLS_DIR) setup_protoc setup_tools

# vendor
setup_vendor:
	go mod vendor

$(_TOOLS_DIR):
	mkdir -v -p $@

# protoc
setup_protoc: $(PROTOC) \
              $(_TOOLS_BIN)/protoc-gen-go \
              $(_TOOLS_BIN)/protoc-gen-twirp \
              $(_TOOLS_BIN)/protoc-gen-twirp_python \
              $(_TOOLS_BIN)/protoc-gen-govalidators \
              $(_TOOLS_BIN)/protoc-gen-twirp_swagger \
              $(_TOOLS_BIN)/protoc-gen-twirp_js \
              $(_TOOLS_BIN)/statik \
              $(_TOOLS_BIN)/goimports

$(PROTOC): $(_TOOLS_DIR)/$(PROTOC_ZIP)
	unzip -o -d $(_TOOLS_DIR) $< && touch $@  # avoid Prerequisite is newer than target `_tools/bin/protoc'.

$(_TOOLS_DIR)/$(PROTOC_ZIP):
	curl --location $(PROTOC_DOWNLOAD) --output $@

$(_TOOLS_BIN)/protoc-gen-go: vendor/github.com/golang/protobuf/protoc-gen-go
$(_TOOLS_BIN)/protoc-gen-twirp: vendor/github.com/twitchtv/twirp/protoc-gen-twirp
$(_TOOLS_BIN)/protoc-gen-twirp_python: vendor/github.com/twitchtv/twirp/protoc-gen-twirp_python
$(_TOOLS_BIN)/protoc-gen-govalidators: vendor/github.com/mwitkow/go-proto-validators/protoc-gen-govalidators
$(_TOOLS_BIN)/protoc-gen-twirp_swagger: vendor/github.com/elliots/protoc-gen-twirp_swagger
$(_TOOLS_BIN)/protoc-gen-twirp_js: vendor/github.com/thechriswalker/protoc-gen-twirp_js
$(_TOOLS_BIN)/statik: vendor/github.com/rakyll/statik
$(_TOOLS_BIN)/goimports: vendor/golang.org/x/tools/cmd/goimports

# tools
setup_tools: $(_TOOLS_BIN)/usql $(_TOOLS_BIN)/xo

$(_TOOLS_BIN)/usql: vendor/github.com/xo/usql
$(_TOOLS_BIN)/xo: vendor/github.com/xo/xo

clean_setup:
	rm -rf $(_TOOLS_DIR)

clean_vendor:
	rm -rf vendor
