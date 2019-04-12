SHELL := /bin/bash
export GOPATH := ${HOME}/go12
.PHONY: resetdb models

#
# Protobuf based service builds. Update SERVICES with changes
#

SERVICES := coin pot

SWAGGER_JSON_FILES := $(SERVICES:%=swaggerui/proto/%/service.swagger.json)
PROTOBUF_PB_FILES := $(SERVICES:%=rpc/proto/%/service.pb.go)
PROTOBUF_TWIRP_FILES := $(SERVICES:%=rpc/proto/%/service.twirp.go)
PROTOBUF_VALIDATOR_FILES := $(SERVICES:%=rpc/proto/%/service.validator.pb.go)

rpc/proto/%/service.twirp.go \
rpc/proto/%/service.pb.go \
rpc/proto/%/service.validator.pb.go \
swaggerui/proto/%/service.swagger.json: proto/%/service.proto
	protoc \
            -I vendor/github.com/grpc-ecosystem/grpc-gateway/ \
            -I vendor/ \
            --proto_path=. \
            --twirp_out=./rpc \
            --go_out=./rpc \
            --govalidators_out=./rpc \
            --twirp_swagger_out=./swaggerui \
            $<

all: services models

services: proto swagger

proto: $(PROTOBUF_PB_FILES) $(PROTOBUF_TWIRP_FILES) $(PROTOBUF_VALIDATOR_FILES)

$(PROTOBUF_PB_FILES) $(PROTOBUF_TWIRP_FILES) $(PROTOBUF_VALIDATOR_FILES): rpc

rpc:
	mkdir -v $@

swagger: swaggerui-statik/statik/statik.go

swaggerui-statik/statik/statik.go: swaggerui/index.html $(SWAGGER_JSON_FILES)
	statik -src=swaggerui -dest=swaggerui-statik

clean: $(PROTOBUF_PB_FILES) $(PROTOBUF_TWIRP_FILES) $(PROTOBUF_VALIDATOR_FILES) $(SWAGGER_JSON_FILES)
	rm -v $^
	rm -vf internal/models/*.xo.go

#
# Database and models
#

MODEL_PATH := internal/models
TEMPLATE_PATH := sql/templates

resetdb:
	rm -vf database.sqlite3
	$(MAKE) database.sqlite3

database.sqlite3:
	source sql/config && usql $$DB -f sql/schema.sqlite3.sql

models:
	mkdir -v -p internal/models
	source sql/config && xo $$DB --int32-type int32 -o $(MODEL_PATH) --template-path $(TEMPLATE_PATH)
	source sql/config && xo $$DB --int32-type int32 -o $(MODEL_PATH) --query-mode --query-type PotsPaged --query-trim < sql/pots_paged.query.sql
	source sql/config && xo $$DB --int32-type int32 -o $(MODEL_PATH) --query-mode --query-type CoinsInPot --query-trim < sql/coins_in_pot.query.sql

setup:
	go get github.com/xo/usql
	go mod vendor
