// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DFSClient",
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
        .package(url: "https://github.com/apple/example-package-figlet", branch: "main"),
        .package(url: "https://github.com/grpc/grpc-swift.git", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(name: "DFSClient", dependencies: [
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
            .product(name: "Figlet", package: "example-package-figlet"),
            .product(name: "GRPC", package: "grpc-swift"),
        ], path: "Sources", resources: [
            .process("proto-src/dfsclient.proto"),
            .process("make_protos.sh")
        ]),
    ]
)
