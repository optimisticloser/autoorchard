// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "swift-autolab",
    platforms: [
        .macOS(.v15),
        .iOS(.v18)
    ],
    products: [
        .library(name: "AutolabCore", targets: ["AutolabCore"]),
        .executable(name: "swift-autolab", targets: ["swift-autolab"])
    ],
    targets: [
        .target(
            name: "AutolabCore",
            path: "Sources/AutolabCore"
        ),
        .executableTarget(
            name: "swift-autolab",
            dependencies: ["AutolabCore"],
            path: "Sources/swift-autolab"
        ),
        .testTarget(
            name: "AutolabCoreTests",
            dependencies: ["AutolabCore"],
            path: "Tests/AutolabCoreTests"
        )
    ]
)
