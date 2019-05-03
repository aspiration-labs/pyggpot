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
STATIK = $(TOOLS_BIN)/statik

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
	PATH="$(TOOLS_BIN):$$PATH" $(PROTOC) \
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
XO = PATH="$(TOOLS_BIN):$$PATH" $(TOOLS_BIN)/xo
USQL = $(TOOLS_BIN)/usql

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
# We use tools.go to trick go mod into getting our tools for local builds.
# See the following for inspiration:
#   https://github.com/golang/go/wiki/Modules#how-can-i-track-tool-dependencies-for-a-module
#   https://github.com/golang/go/issues/25922
#   https://github.com/go-modules-by-example/index/blob/master/010_tools/README.md
#   

TOOLS_DIR := ./tools
TOOLS_BIN := $(TOOLS_DIR)/bin

# protoc
PROTOC_VERSION := 3.7.1
PROTOC_RELEASES_PATH := https://github.com/protocolbuffers/protobuf/releases/download
PROTOC_ZIP := protoc-$(PROTOC_VERSION)-$(PROTOC_PLATFORM).zip
PROTOC_DOWNLOAD := $(PROTOC_RELEASES_PATH)/v$(PROTOC_VERSION)/$(PROTOC_ZIP)
PROTOC := $(TOOLS_BIN)/protoc

# go installed tools.go
GO_TOOLS := github.com/golang/protobuf/protoc-gen-go \
            github.com/twitchtv/twirp/protoc-gen-twirp \
            github.com/twitchtv/twirp/protoc-gen-twirp_python \
            github.com/mwitkow/go-proto-validators/protoc-gen-govalidators \
            github.com/elliots/protoc-gen-twirp_swagger \
            github.com/thechriswalker/protoc-gen-twirp_js \
            github.com/rakyll/statik \
            golang.org/x/tools/cmd/goimports \
            github.com/xo/usql \
            github.com/xo/xo

setup: setup_vendor $(TOOLS_DIR) $(PROTOC) setup_tools

# vendor
setup_vendor:
	go mod vendor

$(TOOLS_DIR):
	mkdir -v -p $@

# protoc
$(PROTOC): $(TOOLS_DIR)/$(PROTOC_ZIP)
	unzip -o -d "$(TOOLS_DIR)" $< && touch $@  # avoid Prerequisite is newer than target `tools/bin/protoc'.

$(TOOLS_DIR)/$(PROTOC_ZIP):
	curl --location $(PROTOC_DOWNLOAD) --output $@

# tools
GO_TOOLS_BIN := $(addprefix $(TOOLS_BIN), $(notdir $(GO_TOOLS)))
GO_TOOLS_VENDOR := $(addprefix vendor/, $(GO_TOOLS))

setup_tools: $(GO_TOOLS_BIN)

$(GO_TOOLS_BIN): $(GO_TOOLS_VENDOR)
	GOBIN="$(PWD)/$(TOOLS_BIN)" go install -mod=vendor $(GO_TOOLS)

# clean
clean_setup:
	rm -rf "$(TOOLS_DIR)"

clean_vendor:
	rm -rf vendor
