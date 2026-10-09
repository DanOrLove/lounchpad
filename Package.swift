// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Lunchpad",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "Lunchpad", targets: ["Lunchpad"])],
    targets: [.executableTarget(name: "Lunchpad")]
)
