import Testing
import UIKit

@testable import InteractiveContainerPanGestureRecognizer

@MainActor
struct InteractiveContainerPanGestureRecognizerTests {
    @Test("A two-page UIPageViewController can move from its second page to its first page")
    func pageViewControllerCanMoveBackWhileTheContainerPanBegins() throws {
        let fixture = PageViewControllerFixture()
        fixture.showSecondPage()

        let pageViewController = fixture.pageViewController
        let secondPage = try #require(pageViewController.viewControllers?.first)
        let scrollView = try #require(pageViewController.view.descendantScrollViews.first)

        #expect(fixture.dataSource.viewControllerBefore(secondPage) === fixture.pages[0])
        let minimumOffset = -scrollView.adjustedContentInset.left
        #expect(scrollView.contentOffset.x <= minimumOffset + 1)

        let recognizer = InteractiveContainerPanGestureRecognizer()

        let shouldBegin = recognizer.shouldBegin(
            location: CGPoint(x: 160, y: 240),
            velocity: CGPoint(x: 200, y: 0),
            scrollView: scrollView
        )

        // This confirms the bug: the page view can move back, while the drawer pan is also allowed to begin.
        #expect(shouldBegin)

        pageViewController.setViewControllers(
            [fixture.pages[0]],
            direction: .reverse,
            animated: false
        )
        #expect(pageViewController.viewControllers?.first === fixture.pages[0])
    }
}

@MainActor
private final class PageViewControllerFixture {
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
    let hostViewController = UIViewController()
    let pageViewController = UIPageViewController(
        transitionStyle: .scroll,
        navigationOrientation: .horizontal
    )
    let pages = [UIViewController(), UIViewController()]
    lazy var dataSource = DataSource(pages: pages)

    init() {
        window.rootViewController = hostViewController
        window.makeKeyAndVisible()

        hostViewController.addChild(pageViewController)
        pageViewController.view.frame = hostViewController.view.bounds
        hostViewController.view.addSubview(pageViewController.view)
        pageViewController.didMove(toParent: hostViewController)
        pageViewController.dataSource = dataSource

        hostViewController.view.layoutIfNeeded()
        pageViewController.view.layoutIfNeeded()
    }

    isolated deinit {
        window.isHidden = true
        window.rootViewController = nil
    }

    func showSecondPage() {
        pageViewController.setViewControllers(
            [pages[0]],
            direction: .forward,
            animated: false
        )
        pageViewController.setViewControllers(
            [pages[1]],
            direction: .forward,
            animated: false
        )
        pageViewController.view.layoutIfNeeded()
    }
}

@MainActor
private final class DataSource: NSObject, UIPageViewControllerDataSource {
    let pages: [UIViewController]

    init(pages: [UIViewController]) {
        self.pages = pages
    }

    func viewControllerBefore(_ viewController: UIViewController) -> UIViewController? {
        guard let index = pages.firstIndex(where: { $0 === viewController }), index > 0 else {
            return nil
        }
        return pages[index - 1]
    }

    func viewControllerAfter(_ viewController: UIViewController) -> UIViewController? {
        guard let index = pages.firstIndex(where: { $0 === viewController }), index + 1 < pages.count else {
            return nil
        }
        return pages[index + 1]
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        viewControllerBefore(viewController)
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        viewControllerAfter(viewController)
    }
}

private extension UIView {
    var descendantScrollViews: [UIScrollView] {
        subviews.flatMap { subview in
            ((subview as? UIScrollView).map { [$0] } ?? [])
                + subview.descendantScrollViews
        }
    }
}
