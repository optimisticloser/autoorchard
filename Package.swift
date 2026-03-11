// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "autoorchard",
    platforms: [
        .macOS(.v15),
        .iOS(.v18)
    ],
    products: [
        .library(name: "AutoOrchardCore", targets: ["AutoOrchardCore"]),
        .executable(name: "autoorchard", targets: ["autoorchard"])
    ],
    targets: [
        .target(
            name: "AutoOrchardCore",
            path: "Sources/AutoOrchardCore"
        ),
        .executableTarget(
            name: "autoorchard",
            dependencies: ["AutoOrchardCore"],
            path: "Sources/autoorchard"
        ),
        .testTarget(
            name: "AutoOrchardCoreTests",
            dependencies: ["AutoOrchardCore"],
            path: "Tests/AutoOrchardCoreTests"
        )
    ]
)
