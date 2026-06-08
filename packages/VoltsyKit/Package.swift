// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "VoltsyKit",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "VoltsyCore", targets: ["VoltsyCore"]),
        .library(name: "BatteryEngines", targets: ["BatteryEngines"]),
        .library(name: "BatteryStore", targets: ["BatteryStore"]),
    ],
    targets: [
        .target(name: "VoltsyCore"),
        .target(name: "BatteryEngines", dependencies: ["VoltsyCore"]),
        .target(name: "BatteryStore", dependencies: ["VoltsyCore"]),
        .testTarget(name: "VoltsyCoreTests", dependencies: ["VoltsyCore"]),
        .testTarget(name: "BatteryEnginesTests", dependencies: ["BatteryEngines"]),
        .testTarget(name: "BatteryStoreTests", dependencies: ["BatteryStore"]),
    ]
)
