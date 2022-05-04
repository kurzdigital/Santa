// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Santa",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "Santa",
            targets: ["Santa"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "Santa",
            dependencies: []
            ),
        .testTarget(
            name: "SantaTests",
            dependencies: ["Santa"]),
    ]
)
