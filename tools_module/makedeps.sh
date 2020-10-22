#!/bin/bash

TOOLS_BIN_DIR="$1"
shift
BUILD_TARGET="$1"
shift

all_targets=""

for SRC in "$@"; do
    DST="$TOOLS_BIN_DIR/$(basename $SRC)"
    all_targets+=" $DST"
done
printf "%s:%s\n\n" "$BUILD_TARGET" "$all_targets"

for SRC in "$@"; do
    DST="$TOOLS_BIN_DIR/$(basename $SRC)"
    printf "%s: %s\n\tGOBIN=%s go install -mod=vendor %s\n\n" "$DST" "vendor/$SRC" "$PWD/$TOOLS_BIN_DIR" "$SRC"
done
