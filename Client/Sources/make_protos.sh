#!/bin/bash
PROTO_DIR="./proto-src"
OUTPUT_DIR="./proto-src"

echo "Cleaning up old generated files"
find "$OUTPUT_DIR" -type f \( -name "*.pb.swift" -o -name "*.grpc.swift" \) -delete

protoc \
  --swift_out="$OUTPUT_DIR" \
  --grpc-swift_out="$OUTPUT_DIR" \
  -I"$PROTO_DIR" \
  "$PROTO_DIR/dfsclient.proto"

echo "Proto files generated in $OUTPUT_DIR"
