#!/bin/bash
PROTO_OUTPUT_DIR="./proto-src"

echo "Cleaning up old generated files"
find "$PROTO_OUTPUT_DIR" -type f \( -name "*.pb.swift" -o -name "*.grpc.swift" \) -delete

protoc \
  --swift_out="$PROTO_OUTPUT_DIR" \
  --grpc-swift_out="$PROTO_OUTPUT_DIR" \
  -I"$PROTO_OUTPUT_DIR" \
  "$PROTO_OUTPUT_DIR/dfsclient.proto"

echo "Proto files generated in $PROTO_OUTPUT_DIR"
