// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "GlassKit",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "GlassKit", targets: ["GlassKit"]),
    ],
    targets: [
        .target(name: "GlassKit"),
        .testTarget(name: "GlassKitTests", dependencies: ["GlassKit"]),
    ]
)
