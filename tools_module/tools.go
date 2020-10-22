// +build tools

package tools

import (
	// protocol buffer compiler plugins
	_ "github.com/elliots/protoc-gen-twirp_swagger"
	_ "github.com/golang/protobuf/protoc-gen-go"
	_ "github.com/mwitkow/go-proto-validators/protoc-gen-govalidators"
	_ "github.com/rakyll/statik"
	_ "github.com/thechriswalker/protoc-gen-twirp_js"
	_ "github.com/twitchtv/twirp/protoc-gen-twirp"
	_ "github.com/twitchtv/twirp/protoc-gen-twirp_python"

	// grpc-gateway, swagger support
	_ "github.com/grpc-ecosystem/grpc-gateway/codegenerator"
	_ "github.com/grpc-ecosystem/grpc-gateway/protoc-gen-grpc-gateway"
	_ "github.com/grpc-ecosystem/grpc-gateway/protoc-gen-swagger"
	_ "github.com/grpc-ecosystem/grpc-gateway/utilities"

	// template processor
	_ "github.com/tsg/gotpl"

	// database
	_ "github.com/xo/usql"
	_ "github.com/xo/xo"
	_ "golang.org/x/tools/cmd/goimports"
)
