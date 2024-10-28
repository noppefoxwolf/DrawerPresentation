# DrawerPresentation

DrawerPresentation is a library that provides a customizable drawer presentation style for iOS applications.

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
let interaction = DrawerInteraction(delegate: self)
navigationController!.view.addInteraction(interaction)

// Delegate Example
extension ViewController: DrawerInteractionDelegate {
    func viewController(for interaction: DrawerInteraction) -> UIViewController {
        self
    }
    
    func drawerInteraction(_ interaction: DrawerInteraction, widthForDrawer drawerViewController: UIViewController) -> CGFloat {
        300
    }
    
    func drawerInteraction(_ interaction: DrawerInteraction, presentingViewControllerFor viewController: UIViewController) -> UIViewController? {
        UIHostingController(rootView: Text("Interactive side menu"))
    }
}

// Perform interaction manually
interaction.present()

// Using transitioningDelegate directly
self.transitionController = DrawerTransitionController(drawerWidth: 300)
let vc = UIHostingController(rootView: Text("Hello, World!!"))
vc.modalPresentationStyle = .custom
vc.transitioningDelegate = transitionController
present(vc, animated: true)
```

## Contributing

Let people know how they can contribute into your project. A contributing guideline will be a big plus.

## Apps Using

<p float="left">
    <a href="https://apps.apple.com/app/id1668645019"><img src="https://is1-ssl.mzstatic.com/image/thumb/Purple221/v4/ca/79/32/ca7932c7-ee99-02e8-4164-2a5a99828070/AppIcon-0-1x_U007epad-0-1-P3-85-220-0.png/100x100bb.jpg" height="65"></a>
</p>

## License

This project is licensed under the terms of the MIT license. See the [LICENSE](LICENSE) file for details.
