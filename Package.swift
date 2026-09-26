// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "swiftui-toasts",
  platforms: [.iOS(.v26)],
  products: [
    .library(
      name: "Toasts",
      targets: ["Toasts"])
  ],
  targets: [
    .target(
      name: "Toasts"
    ),
    .testTarget(
      name: "ToastManagerTests",
      dependencies: ["Toasts"]
    ),
  ]
)
