#!/bin/bash

# Define paths relative to the current working directory
PROTO_DIR="./Sources/src"             # Directory containing the .proto file
OUTPUT_DIR="./Sources/proto-src"      # Output directory for generated Swift files


# Run protoc to generate Swift and gRPC files
protoc \
  --swift_out="$OUTPUT_DIR" \
  --grpc-swift_out="$OUTPUT_DIR" \
  -I"$PROTO_DIR" \
  "$PROTO_DIR/dfsclient"

echo "Proto files generated in $OUTPUT_DIR"
