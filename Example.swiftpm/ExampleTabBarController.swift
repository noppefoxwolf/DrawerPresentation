import UIKit
import SwiftUI
import DrawerPresentation

@MainActor
final class ExampleTabBarController: UITabBarController, DrawerInteractionDelegate, ExampleSideMenuViewControllerDelegate {
    private lazy var drawerInteraction = DrawerInteraction(delegate: self)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addInteraction(drawerInteraction)

        let plainViewController = UINavigationController(
            rootViewController: PlainViewController()
        )
        plainViewController.tabBarItem = UITabBarItem(
            title: "View",
            image: UIImage(systemName: "rectangle"),
            tag: 0
        )

        let scrollViewController = UINavigationController(
            rootViewController: ScrollViewController()
        )
        scrollViewController.tabBarItem = UITabBarItem(
            title: "Scroll",
            image: UIImage(systemName: "rectangle.split.3x1"),
            tag: 1
        )

        let pageViewController = UINavigationController(
            rootViewController: PageViewController()
        )
        pageViewController.tabBarItem = UITabBarItem(
            title: "Pages",
            image: UIImage(systemName: "square.stack.3d.forward.dottedline"),
            tag: 2
        )

        let splitViewController = ExampleSplitViewController()
        splitViewController.tabBarItem = UITabBarItem(
            title: "Split",
            image: UIImage(systemName: "rectangle.split.2x1"),
            tag: 3
        )

        let nestedCollectionViewController = UINavigationController(
            rootViewController: NestedCollectionViewController()
        )
        nestedCollectionViewController.tabBarItem = UITabBarItem(
            title: "Nested",
            image: UIImage(systemName: "rectangle.stack"),
            tag: 4
        )

        let settingsViewController = UINavigationController(
            rootViewController: ExampleSettingsViewController()
        )
        settingsViewController.tabBarItem = UITabBarItem(
            title: "Settings",
            image: UIImage(systemName: "gearshape"),
            tag: 5
        )

        viewControllers = [
            plainViewController,
            scrollViewController,
            pageViewController,
            splitViewController,
            nestedCollectionViewController,
            settingsViewController,
        ]
    }

    func presentDrawer() {
        updateDrawerSettings()
        drawerInteraction.present()
    }

    func updateDrawerSettings() {
        drawerInteraction.movesPresentingView = ExampleSettings.shared.movesPresentingView
    }

    func viewController(for interaction: DrawerInteraction) -> UIViewController {
        self
    }

    func drawerInteraction(
        _ interaction: DrawerInteraction,
        widthForDrawer drawerViewController: UIViewController
    ) -> CGFloat {
        300
    }

    func drawerInteraction(
        _ interaction: DrawerInteraction,
        presentingViewControllerFor viewController: UIViewController
    ) -> UIViewController? {
        let sideMenuViewController = ExampleSideMenuViewController()
        sideMenuViewController.delegate = self
        return sideMenuViewController
    }

    func exampleSideMenuViewControllerDidSelect(_ viewController: ExampleSideMenuViewController) {
        viewController.dismiss(animated: true)
        activeNavigationController?.pushViewController(
            UIHostingController(rootView: Text("Child View")),
            animated: true
        )
    }

    private var activeNavigationController: UINavigationController? {
        guard let selectedViewController else { return nil }

        if let navigationController = selectedViewController as? UINavigationController {
            return navigationController
        }

        if let splitViewController = selectedViewController as? UISplitViewController {
            return splitViewController.viewController(for: .secondary) as? UINavigationController
                ?? splitViewController.viewController(for: .primary) as? UINavigationController
        }

        return selectedViewController.navigationController
    }
}
