// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "swiftui-toasts",
  defaultLocalization: "en",
  platforms: [.iOS(.v26)],
  products: [
    .library(
      name: "Toasts",
      targets: ["Toasts"])
  ],
  targets: [
    .target(
      name: "Toasts",
      resources: [.process("Resources")]
    ),
    .testTarget(
      name: "ToastManagerTests",
      dependencies: ["Toasts"]
    ),
  ]
)
