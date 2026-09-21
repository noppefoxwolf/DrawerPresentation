# SidebarPresentation

SidebarPresentation is a library that provides a customizable sidebar presentation style for iOS applications.

![](https://github.com/noppefoxwolf/DrawerPresentation/blob/main/.github/example.gif)

## Installation

```
.target(
    name: "YourProject",
    dependencies: [
        .package(url: "https://github.com/noppefoxwolf/DrawerPresentation", from: "1.0.0")
    ]
)
```

## Usage

```swift

// Add Interaction
let interaction = SidebarInteraction(delegate: self)
interaction.movesPresentingView = false
view.addInteraction(interaction)

// Delegate Example
extension ViewController: SidebarInteractionDelegate {
    func viewController(for interaction: SidebarInteraction) -> UIViewController {
        self
    }
    
    func sidebarInteraction(_ interaction: SidebarInteraction, widthForSidebar sidebarViewController: UIViewController) -> CGFloat {
        SidebarTransitionController.defaultSidebarWidth
    }
    
    func sidebarInteraction(_ interaction: SidebarInteraction, presentingViewControllerFor viewController: UIViewController) -> UIViewController? {
        UIHostingController(rootView: Text("Interactive side menu"))
    }
}

// Perform interaction manually
interaction.present()

// Using transitioningDelegate directly
self.transitionController = SidebarTransitionController(
    movesPresentingView: false
)
let vc = UIHostingController(rootView: Text("Hello, World!!"))
vc.modalPresentationStyle = .custom
vc.transitioningDelegate = transitionController
present(vc, animated: true)
```

## Contributing

Let people know how they can contribute into your project. A contributing guideline will be a big plus.

## Build and Test

This repository is an iOS Swift package. Use `xcodebuild` with an iOS Simulator destination.

List available simulator destinations:

```sh
xcodebuild -scheme SidebarPresentation -sdk iphonesimulator -showdestinations
```

Build for the iOS Simulator:

```sh
xcodebuild \
    -scheme SidebarPresentation \
    -destination 'generic/platform=iOS Simulator' \
    build
```

Run tests on a specific available simulator:

```sh
xcodebuild \
    -scheme SidebarPresentation \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
    test
```

Replace the simulator name and OS version with a destination returned by `-showdestinations` when necessary.

Build the Example app:

```sh
cd Example.swiftpm
xcodebuild \
    -scheme Playground \
    -destination 'generic/platform=iOS Simulator' \
    build
```

## Apps Using

<p float="left">
    <a href="https://apps.apple.com/app/id1668645019"><img src="https://is1-ssl.mzstatic.com/image/thumb/Purple221/v4/ca/79/32/ca7932c7-ee99-02e8-4164-2a5a99828070/AppIcon-0-1x_U007epad-0-1-P3-85-220-0.png/100x100bb.jpg" height="65"></a>
</p>

## License

This project is licensed under the terms of the MIT license. See the [LICENSE](LICENSE) file for details.
