// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "MathGateCore", products: [
    .library(name: "MathGateCore", targets: ["MathGateCore"])
], targets: [
    .target(name: "MathGateCore", path: "Core"),
    .testTarget(name: "MathGateCoreTests", dependencies: ["MathGateCore"], path: "Tests")
])
