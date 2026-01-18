// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PersonalAI",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "PersonalAI",
            targets: ["PersonalAI"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "PersonalAI",
            dependencies: [],
            path: "Sources",
            resources: [
                .process("Persistence/CoreDataStack/PersonalAI.xcdatamodeld")
            ]
        ),
        .testTarget(
            name: "PersonalAITests",
            dependencies: ["PersonalAI"],
            path: "Tests"
        )
    ]
)
