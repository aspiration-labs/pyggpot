
#
# Setup: protoc+plugins, other tools
#
# Note that go mod vendor will bring down *versioned* tools base on go.mod. Yay.
# We use tools_modeule/tools.go to trick go mod into getting our tools for local builds.
# See the following for inspiration:
#   https://github.com/golang/go/wiki/Modules#how-can-i-track-tool-dependencies-for-a-module
#   https://github.com/golang/go/issues/25922
#   https://github.com/go-modules-by-example/index/blob/master/010_tools/README.md
#   

include ../build/makefiles/shellvars.mk
include ../build/makefiles/osvars.mk

TOOLS_DIR := ./tools
TOOLS_BIN_DIR := $(TOOLS_DIR)/bin

#
# protoccol compiler
# ------------------
PROTOC_VERSION := 3.7.1
PROTOC_RELEASES_PATH := https://github.com/protocolbuffers/protobuf/releases/download
PROTOC_ZIP := protoc-$(PROTOC_VERSION)-$(PROTOC_PLATFORM).zip
PROTOC_DOWNLOAD := $(PROTOC_RELEASES_PATH)/v$(PROTOC_VERSION)/$(PROTOC_ZIP)
PROTOC := $(TOOLS_BIN_DIR)/protoc

#
# tools and protoc plugins to be installed via go install
# -------------------------------------------------------
GO_TOOLS_SRC := github.com/golang/protobuf/protoc-gen-go \
            github.com/twitchtv/twirp/protoc-gen-twirp \
            github.com/twitchtv/twirp/protoc-gen-twirp_python \
            github.com/mwitkow/go-proto-validators/protoc-gen-govalidators \
            github.com/elliots/protoc-gen-twirp_swagger \
            github.com/thechriswalker/protoc-gen-twirp_js \
            github.com/rakyll/statik \
            github.com/xo/usql \
            github.com/xo/xo \
            golang.org/x/tools/cmd/goimports
GO_TOOLS_BIN := $(addprefix $(TOOLS_BIN_DIR), $(notdir $(GO_TOOLS_SRC)))
GO_TOOLS_MAKEFILE := .go_tools.mk


tools: $(PROTOC) go_tools_bin

$(PROTOC): | $(TOOLS_BIN_DIR)
	curl --location $(PROTOC_DOWNLOAD) --output $(TOOLS_DIR)/$(PROTOC_ZIP)
	unzip -o -d "$(TOOLS_DIR)" $(TOOLS_DIR)/$(PROTOC_ZIP) && touch $@

go_tools_bin: vendor $(GO_TOOLS_MAKEFILE) | $(TOOLS_BIN_DIR)
	make -f $(GO_TOOLS_MAKEFILE)

vendor: tools.go go.mod
	go mod vendor

$(GO_TOOLS_MAKEFILE): Makefile
	./makedeps.sh $(TOOLS_BIN_DIR) go_tools_bin $(GO_TOOLS_SRC) >$@

$(TOOLS_BIN_DIR):
	mkdir -v -p $@

# clean
# -----
clean:
	rm -rf "$(TOOLS_DIR)" vendor $(GO_TOOLS_MAKEFILE)
