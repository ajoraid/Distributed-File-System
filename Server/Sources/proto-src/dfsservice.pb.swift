// DO NOT EDIT.
// swift-format-ignore-file
// swiftlint:disable all
//
// Generated by the Swift generator plugin for the protocol buffer compiler.
// Source: dfsservice.proto
//
// For information on using the generated types, please see the documentation:
//   https://github.com/apple/swift-protobuf/

import Foundation
import SwiftProtobuf

// If the compiler emits an error on this type, it is because this file
// was generated by a version of the `protoc` Swift plug-in that is
// incompatible with the version of SwiftProtobuf to which you are linking.
// Please ensure that you are building against the same version of the API
// that was used to generate this file.
fileprivate struct _GeneratedWithProtocGenSwiftVersion: SwiftProtobuf.ProtobufAPIVersionCheck {
  struct _2: SwiftProtobuf.ProtobufAPIVersion_2 {}
  typealias Version = _2
}

struct FilesList: Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var files: [FileRequest] = []

  var tombstones: [Stones] = []

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}
}

struct Stones: Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var fileName: String = String()

  var deletionTime: UInt64 = 0

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}
}

struct FileRequest: @unchecked Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var fileName: String = String()

  var fileContent: Data = Data()

  var fileChecksum: UInt32 = 0

  var mtime: UInt64 = 0

  var userid: String = String()

  var ctime: UInt64 = 0

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}
}

struct FileContent: @unchecked Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var bytesWritten: Int64 = 0

  var fileContent: Data = Data()

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}
}

struct EmptyResponse: Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}
}

// MARK: - Code below here is support for the SwiftProtobuf runtime.

extension FilesList: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = "FilesList"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "files"),
    2: .same(proto: "tombstones"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeRepeatedMessageField(value: &self.files) }()
      case 2: try { try decoder.decodeRepeatedMessageField(value: &self.tombstones) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.files.isEmpty {
      try visitor.visitRepeatedMessageField(value: self.files, fieldNumber: 1)
    }
    if !self.tombstones.isEmpty {
      try visitor.visitRepeatedMessageField(value: self.tombstones, fieldNumber: 2)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: FilesList, rhs: FilesList) -> Bool {
    if lhs.files != rhs.files {return false}
    if lhs.tombstones != rhs.tombstones {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Stones: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = "Stones"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "fileName"),
    2: .same(proto: "deletionTime"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularStringField(value: &self.fileName) }()
      case 2: try { try decoder.decodeSingularUInt64Field(value: &self.deletionTime) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.fileName.isEmpty {
      try visitor.visitSingularStringField(value: self.fileName, fieldNumber: 1)
    }
    if self.deletionTime != 0 {
      try visitor.visitSingularUInt64Field(value: self.deletionTime, fieldNumber: 2)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: Stones, rhs: Stones) -> Bool {
    if lhs.fileName != rhs.fileName {return false}
    if lhs.deletionTime != rhs.deletionTime {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension FileRequest: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = "FileRequest"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "fileName"),
    2: .same(proto: "fileContent"),
    3: .same(proto: "fileChecksum"),
    4: .same(proto: "mtime"),
    5: .same(proto: "userid"),
    6: .same(proto: "ctime"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularStringField(value: &self.fileName) }()
      case 2: try { try decoder.decodeSingularBytesField(value: &self.fileContent) }()
      case 3: try { try decoder.decodeSingularUInt32Field(value: &self.fileChecksum) }()
      case 4: try { try decoder.decodeSingularUInt64Field(value: &self.mtime) }()
      case 5: try { try decoder.decodeSingularStringField(value: &self.userid) }()
      case 6: try { try decoder.decodeSingularUInt64Field(value: &self.ctime) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.fileName.isEmpty {
      try visitor.visitSingularStringField(value: self.fileName, fieldNumber: 1)
    }
    if !self.fileContent.isEmpty {
      try visitor.visitSingularBytesField(value: self.fileContent, fieldNumber: 2)
    }
    if self.fileChecksum != 0 {
      try visitor.visitSingularUInt32Field(value: self.fileChecksum, fieldNumber: 3)
    }
    if self.mtime != 0 {
      try visitor.visitSingularUInt64Field(value: self.mtime, fieldNumber: 4)
    }
    if !self.userid.isEmpty {
      try visitor.visitSingularStringField(value: self.userid, fieldNumber: 5)
    }
    if self.ctime != 0 {
      try visitor.visitSingularUInt64Field(value: self.ctime, fieldNumber: 6)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: FileRequest, rhs: FileRequest) -> Bool {
    if lhs.fileName != rhs.fileName {return false}
    if lhs.fileContent != rhs.fileContent {return false}
    if lhs.fileChecksum != rhs.fileChecksum {return false}
    if lhs.mtime != rhs.mtime {return false}
    if lhs.userid != rhs.userid {return false}
    if lhs.ctime != rhs.ctime {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension FileContent: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = "FileContent"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "bytesWritten"),
    2: .same(proto: "fileContent"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularInt64Field(value: &self.bytesWritten) }()
      case 2: try { try decoder.decodeSingularBytesField(value: &self.fileContent) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if self.bytesWritten != 0 {
      try visitor.visitSingularInt64Field(value: self.bytesWritten, fieldNumber: 1)
    }
    if !self.fileContent.isEmpty {
      try visitor.visitSingularBytesField(value: self.fileContent, fieldNumber: 2)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: FileContent, rhs: FileContent) -> Bool {
    if lhs.bytesWritten != rhs.bytesWritten {return false}
    if lhs.fileContent != rhs.fileContent {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension EmptyResponse: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = "EmptyResponse"
  static let _protobuf_nameMap = SwiftProtobuf._NameMap()

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    // Load everything into unknown fields
    while try decoder.nextFieldNumber() != nil {}
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: EmptyResponse, rhs: EmptyResponse) -> Bool {
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}
