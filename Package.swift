// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TieraVPNEngine",
    platforms: [
        .iOS(.v15),
        .macOS(.v13)
    ],
    products: [
      .library(
        name: "TieraVPNEngine",
        targets: ["TieraVPNEngine"]
      ),
    ],
    dependencies: [
      .package(url: "https://github.com/shizong888/TieraVPNCore", from: "1.1.0")
    ],
    targets: [
      .target(
        name: "TieraVPNEngine",
        dependencies: [
          .product(name: "TieraVPNCore", package: "TieraVPNCore")
        ],
        path: "Sources/TieraVPNEngine",
        linkerSettings: [
          .linkedLibrary("resolv")
        ]
      ),
      .testTarget(
        name: "TieraVPNEngineTests",
        dependencies: ["TieraVPNEngine"],
        path: "Tests/TieraVPNEngineTests"
      ),
    ]
)
