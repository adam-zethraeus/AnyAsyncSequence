// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AnyAsyncSequence",
    platforms: [.iOS(.v16)],
    products: [
        .library(
            name: "AnyAsyncSequence",
            targets: ["AnyAsyncSequence"]),
    ],
    targets: [
        .target(
            name: "AnyAsyncSequence"),
        .testTarget(
            name: "AnyAsyncSequenceTests",
            dependencies: ["AnyAsyncSequence"]
        ),
    ]
)
