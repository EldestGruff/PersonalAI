// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "STASH",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "STASH",
            targets: ["STASH"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "STASH",
            dependencies: [],
            path: "Sources",
            resources: [
                .process("Persistence/CoreDataStack/STASH.xcdatamodeld")
            ]
        ),
        .testTarget(
            name: "STASHTests",
            dependencies: ["STASH"],
            path: "Tests"
        )
    ]
)
