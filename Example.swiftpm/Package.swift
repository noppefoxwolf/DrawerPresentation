// swift-tools-version: 6.3

import AppleProductTypes
import PackageDescription

let package = Package(
    name: "Playground",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .iOSApplication(
            name: "Playground",
            targets: ["AppModule"],
            bundleIdentifier: "D7E9E73B-EC8A-4C1D-9264-C96BB5A4ABFE",
            teamIdentifier: "",
            displayVersion: "1.0",
            bundleVersion: "1",
            supportedDeviceFamilies: [
                .pad,
                .phone,
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft,
                .portraitUpsideDown(.when(deviceFamilies: [.pad])),
            ]
        )
    ],

    dependencies: [
        .package(name: "SidebarPresentation", path: "../")
    ],

    targets: [
        .executableTarget(
            name: "AppModule",

            dependencies: [
                .product(name: "SidebarPresentation", package: "SidebarPresentation"),
                .product(name: "AlternativeSidebar", package: "SidebarPresentation"),
            ],

            path: "."
        )
    ]
)
