// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DFSClient",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
        .package(url: "https://github.com/apple/example-package-figlet", branch: "main"),
        .package(url: "https://github.com/grpc/grpc-swift.git", from: "1.0.0"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "1.8.3")
    ],
    targets: [
        .executableTarget(name: "DFSClient", dependencies: [
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
            .product(name: "Figlet", package: "example-package-figlet"),
            .product(name: "GRPC", package: "grpc-swift"),
            .product(name: "CryptoSwift", package: "CryptoSwift")
        ], path: "Sources", resources: [
            .process("proto-src/dfsservice.proto"),
            .process("make_protos.sh")
        ]),
    ]
)
