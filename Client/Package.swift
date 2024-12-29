// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DFSClient",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
        .package(url: "https://github.com/apple/example-package-figlet", branch: "main"),
        .package(url: "https://github.com/grpc/grpc-swift.git", from: "1.24.0"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "1.8.3"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),

    ],
    targets: [
        .executableTarget(name: "DFSClient", dependencies: [
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
            .product(name: "Figlet", package: "example-package-figlet"),
            .product(name: "GRPC", package: "grpc-swift"),
            .product(name: "CryptoSwift", package: "CryptoSwift"),
            .product(name: "Vapor", package: "vapor")
        ], path: "Sources", resources: [
            .process("proto-src/dfsservice.proto"),
            .process("make_protos.sh")
        ]),
    ]
)
