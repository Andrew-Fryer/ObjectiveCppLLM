// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AI_CLI",
    platforms: [.macOS(.v15)],
    targets: [
        .target(
            name: "AI_CLI_Core"
        ),
        .executableTarget(
            name: "AI_CLI",
            dependencies: ["AI_CLI_Core"]
        ),
        .target(
            name: "AI_CLI_Bridge",
            dependencies: ["AI_CLI_Core"]
        ),
        .executableTarget(
            name: "AI_CLI_ObjCpp",
            dependencies: ["AI_CLI_Bridge"],
            sources: ["main.mm", "AI_CLI_Bridge.mm"],
            publicHeadersPath: ".",
            cxxSettings: [
                .headerSearchPath("."),
                .define("SWIFT_PACKAGE")
            ],
            linkerSettings: [
                .linkedFramework("Foundation")
            ]
        ),
    ]
)
