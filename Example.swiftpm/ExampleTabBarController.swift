import UIKit

@MainActor
final class ExampleTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()

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

        viewControllers = [
            plainViewController,
            scrollViewController,
            pageViewController,
            splitViewController,
        ]
    }
}
