// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "Buddy",
    platforms: [.macOS(.v13)],
    targets: [
        .target(
            name: "BuddyCore",
            path: "Sources/BuddyCore"
        ),
        .executableTarget(
            name: "BuddyApp",
            dependencies: ["BuddyCore"],
            path: "Sources/BuddyApp",
            linkerSettings: [
                .linkedFramework("Cocoa"),
            ]
        ),
        .executableTarget(
            name: "BuddyCoreTests",
            dependencies: ["BuddyCore"],
            path: "Tests/BuddyCoreTests"
        ),
    ]
)
