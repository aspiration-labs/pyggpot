.PHONY: resetdb models

include build/makefiles/shellvars.mk
include build/makefiles/osvars.mk

all: models services
setup:
	make -C tools_module

clean: clean_services clean_models
distclean: clean_services clean_models clean_db
	make -C tools_module clean

#
# Services: protobuf based service builds. Typically just add to SERVICES var.
#

SERVICES := coin pot

TOOLS_BIN_DIR := tools_module/tools/bin
PROTOC := $(TOOLS_BIN_DIR)/protoc
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
STATIK = $(TOOLS_BIN_DIR)/statik

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
	PATH="$(TOOLS_BIN_DIR):$$PATH" $(PROTOC) \
            --proto_path=./proto \
            --proto_path=./tools_module/vendor \
            --proto_path=./tools_module/vendor/github.com/grpc-ecosystem/grpc-gateway \
            --twirp_out=./rpc/go \
            --go_out=./rpc/go \
            --go_opt=paths=source_relative \
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
XO = PATH="$(TOOLS_BIN_DIR):$$PATH" $(TOOLS_BIN_DIR)/xo
USQL = $(TOOLS_BIN_DIR)/usql

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


