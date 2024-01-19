# DrawerPresentation

DrawerPresentation is a library that provides a customizable drawer presentation style for iOS applications.

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
let drawerTransitionController = DrawerTransitionController()

// add interactive gesture and register drawer
drawerTransitionController.addDrawerGesture(to: self, drawerViewController: {
    UIHostingController(rootView: Text("Interactive side menu"))
})

// present registered drawer manually
drawerTransitionController.presentRegisteredDrawer()

// present drawer manually
let vc = UIHostingController(rootView: Text("Hello, World!!"))
vc.modalPresentationStyle = .custom
vc.transitioningDelegate = drawerTransitionController
present(vc, animated: true)
```

## Contributing

Let people know how they can contribute into your project. A contributing guideline will be a big plus.

## License

This project is licensed under the terms of the MIT license. See the [LICENSE](LICENSE) file for details.
