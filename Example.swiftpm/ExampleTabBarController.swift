import AlternativeSidebar
import UIKit

@MainActor
final class ExampleTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()

        mode = .tabSidebar

        updateSidebarSettings()

        let plainViewController = UINavigationController(
            rootViewController: PlainViewController()
        )

        let scrollViewController = UINavigationController(
            rootViewController: ScrollViewController()
        )

        let pageViewController = UINavigationController(
            rootViewController: PageViewController()
        )

        let splitViewController = ExampleSplitViewController()

        let nestedCollectionViewController = UINavigationController(
            rootViewController: NestedCollectionViewController()
        )

        let settingsViewController = UINavigationController(
            rootViewController: ExampleSettingsViewController()
        )

        tabs = [
            makeTab(
                title: "View",
                imageName: "rectangle",
                identifier: "view",
                viewController: plainViewController
            ),
            makeTab(
                title: "Scroll",
                imageName: "rectangle.split.3x1",
                identifier: "scroll",
                viewController: scrollViewController
            ),
            makeTab(
                title: "Pages",
                imageName: "square.stack.3d.forward.dottedline",
                identifier: "pages",
                viewController: pageViewController
            ),
            makeTab(
                title: "Split",
                imageName: "rectangle.split.2x1",
                identifier: "split",
                viewController: splitViewController
            ),
            makeTab(
                title: "Nested",
                imageName: "rectangle.stack",
                identifier: "nested",
                viewController: nestedCollectionViewController
            ),
            makeTab(
                title: "Settings",
                imageName: "gearshape",
                identifier: "settings",
                viewController: settingsViewController
            ),
        ]

        configureSidebar()
    }

    private func makeTab(
        title: String,
        imageName: String,
        identifier: String,
        viewController: UIViewController
    ) -> UITab {
        UITab(
            title: title,
            image: UIImage(systemName: imageName),
            identifier: identifier
        ) { _ in
            viewController
        }
    }

    func presentSidebar() {
        updateSidebarSettings()
        preferredSidebar.isHidden.toggle()
    }

    func updateSidebarSettings() {
        alternativeSidebar.isEnabled = ExampleSettings.shared.isSidebarEnabled
    }

    private var sidebarHeaderConfiguration: UIContentConfiguration {
        var configuration = UIListContentConfiguration.header()
        configuration.text = "SidebarSample"
        configuration.secondaryText = "SidebarPresentation"
        configuration.image = UIImage(systemName: "sidebar.left")
        configuration.imageProperties.tintColor = UIColor.systemBlue
        return configuration
    }

    private var sidebarFooterConfiguration: UIContentConfiguration {
        var configuration = UIListContentConfiguration.footer()
        configuration.text = "Swipe right to close"
        return configuration
    }

    private func configureSidebar() {
        sidebar.headerContentConfiguration = sidebarHeaderConfiguration
        sidebar.footerContentConfiguration = sidebarFooterConfiguration
        sidebar.bottomBarView = ExampleSidebarBottomView()

        alternativeSidebar.headerContentConfiguration = sidebarHeaderConfiguration
        alternativeSidebar.footerContentConfiguration = sidebarFooterConfiguration
        alternativeSidebar.bottomBarView = ExampleSidebarBottomView()
    }

    @objc
    private func closeSidebar() {
        presentedViewController?.dismiss(animated: true)
    }

}
