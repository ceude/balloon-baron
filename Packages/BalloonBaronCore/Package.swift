// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "BalloonBaronCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "BalloonBaronCore", targets: ["BalloonBaronCore"])
    ],
    targets: [
        .target(name: "BalloonBaronCore"),
        .testTarget(name: "BalloonBaronCoreTests", dependencies: ["BalloonBaronCore"])
    ]
)
