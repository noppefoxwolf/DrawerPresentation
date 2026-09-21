import CompactSidebar
import SidebarPresentation
import UIKit

@MainActor
final class ExampleTabBarController: UITabBarController, SidebarInteractionDelegate,
    CompactSidebarViewControllerDelegate
{
    private lazy var sidebarInteraction = SidebarInteraction(delegate: self)

    override func viewDidLoad() {
        super.viewDidLoad()

        mode = .tabSidebar

        view.addInteraction(sidebarInteraction)
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
        if #available(iOS 27.0, *) {
            if sidebar.isAvailable {
                sidebar.isHidden.toggle()
            } else {
                sidebarInteraction.present()
            }
        } else {
            sidebarInteraction.present()
        }
    }

    func updateSidebarSettings() {
        sidebarInteraction.isEnabled = ExampleSettings.shared.isSidebarEnabled
        sidebarInteraction.movesPresentingView = ExampleSettings.shared.movesPresentingView
    }

    func viewController(for interaction: SidebarInteraction) -> UIViewController {
        self
    }

    func sidebarInteraction(
        _ interaction: SidebarInteraction,
        widthForSidebar sidebarViewController: UIViewController
    ) -> CGFloat {
        SidebarTransitionController.defaultSidebarWidth
    }

    func sidebarInteraction(
        _ interaction: SidebarInteraction,
        presentingViewControllerFor viewController: UIViewController
    ) -> UIViewController? {
        let sidebarViewController = CompactSidebarViewController(
            tabs: tabs,
            selectedTab: selectedTab,
            headerConfiguration: sidebar.headerContentConfiguration,
            footerConfiguration: sidebar.footerContentConfiguration,
            bottomView: ExampleSidebarBottomView()
        )
        sidebarViewController.delegate = self

        let navigationController = UINavigationController(
            rootViewController: sidebarViewController
        )
        let closeButton = UIBarButtonItem(
            image: UIImage(systemName: "platter.filled.bottom.iphone"),
            style: .plain,
            target: nil,
            action: nil
        )
        closeButton.accessibilityLabel = "Close Sidebar"
        closeButton.primaryAction = UIAction { [weak navigationController] _ in
            navigationController?.dismiss(animated: true)
        }
        sidebarViewController.navigationItem.rightBarButtonItem = closeButton

        return navigationController
    }

    func compactSidebarViewController(
        _ viewController: CompactSidebarViewController,
        didSelect tab: UITab
    ) {
        selectedTab = tab
        viewController.navigationController?.dismiss(animated: true)
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
    }

    @objc
    private func closeSidebar() {
        presentedViewController?.dismiss(animated: true)
    }

}
