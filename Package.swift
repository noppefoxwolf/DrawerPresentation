// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DrawerPresentation",
    platforms: [.iOS(.v18)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "DrawerPresentation",
            targets: ["DrawerPresentation"]
        ),
        .library(
            name: "CompactSidebar",
            targets: ["CompactSidebar"]
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "InteractiveContainerPanGestureRecognizer"
        ),
        .target(
            name: "DrawerPresentation",
            dependencies: ["InteractiveContainerPanGestureRecognizer"]
        ),
        .target(
            name: "CompactSidebar"
        ),
        .testTarget(
            name: "DrawerPresentationTests",
            dependencies: [
                "DrawerPresentation",
                "InteractiveContainerPanGestureRecognizer",
            ]
        ),
    ]
)
