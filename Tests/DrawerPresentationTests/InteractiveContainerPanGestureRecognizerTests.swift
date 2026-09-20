import Testing
import UIKit

@testable import InteractiveContainerPanGestureRecognizer

@MainActor
struct InteractiveContainerPanGestureRecognizerTests {
    @Test("A page transition takes priority over the container pan")
    func pageViewControllerPanTakesPriorityWhenPreviousPageExists() throws {
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

        #expect(!shouldBegin)

        pageViewController.setViewControllers(
            [fixture.pages[0]],
            direction: .reverse,
            animated: false
        )
        #expect(pageViewController.viewControllers?.first === fixture.pages[0])
    }

    @Test("The container pan can begin when a page view controller has no previous page")
    func containerPanBeginsOnTheFirstPage() throws {
        let fixture = PageViewControllerFixture()
        fixture.showFirstPage()

        let pageViewController = fixture.pageViewController
        let firstPage = try #require(pageViewController.viewControllers?.first)
        let scrollView = try #require(pageViewController.view.descendantScrollViews.first)

        #expect(fixture.dataSource.viewControllerBefore(firstPage) == nil)

        let recognizer = InteractiveContainerPanGestureRecognizer()
        let shouldBegin = recognizer.shouldBegin(
            location: CGPoint(x: 160, y: 240),
            velocity: CGPoint(x: 200, y: 0),
            scrollView: scrollView
        )

        #expect(shouldBegin)
    }

    @Test("A page transition takes priority over the container pan when a next page exists")
    func pageViewControllerPanTakesPriorityWhenNextPageExists() throws {
        let fixture = PageViewControllerFixture()
        fixture.showFirstPage()

        let pageViewController = fixture.pageViewController
        let firstPage = try #require(pageViewController.viewControllers?.first)
        let scrollView = try #require(pageViewController.view.descendantScrollViews.first)

        #expect(fixture.dataSource.viewControllerAfter(firstPage) === fixture.pages[1])

        let recognizer = InteractiveContainerPanGestureRecognizer()
        recognizer.direction = .left
        let shouldBegin = recognizer.shouldBegin(
            location: CGPoint(x: 160, y: 240),
            velocity: CGPoint(x: -200, y: 0),
            scrollView: scrollView
        )

        #expect(!shouldBegin)
    }

    @Test("The container pan can begin on the last page when there is no next page")
    func containerPanBeginsOnTheLastPage() throws {
        let fixture = PageViewControllerFixture()
        fixture.showLastPage()

        let pageViewController = fixture.pageViewController
        let lastPage = try #require(pageViewController.viewControllers?.first)
        let scrollView = try #require(pageViewController.view.descendantScrollViews.first)

        #expect(fixture.dataSource.viewControllerAfter(lastPage) == nil)

        let recognizer = InteractiveContainerPanGestureRecognizer()
        recognizer.direction = .left
        let shouldBegin = recognizer.shouldBegin(
            location: CGPoint(x: 160, y: 240),
            velocity: CGPoint(x: -200, y: 0),
            scrollView: scrollView
        )

        #expect(shouldBegin)
    }

    @Test("The navigation pop gesture takes priority inside a navigation controller")
    func navigationPopGestureTakesPriority() throws {
        let navigationController = UINavigationController(
            rootViewController: UIViewController()
        )
        navigationController.pushViewController(UIViewController(), animated: false)
        navigationController.loadViewIfNeeded()

        let recognizer = InteractiveContainerPanGestureRecognizer()
        navigationController.view.addGestureRecognizer(recognizer)
        let popGesture = try #require(navigationController.interactivePopGestureRecognizer)

        #expect(
            recognizer.gestureRecognizer(
                recognizer,
                shouldRequireFailureOf: popGesture
            )
        )

        let rootNavigationController = UINavigationController(
            rootViewController: UIViewController()
        )
        rootNavigationController.loadViewIfNeeded()
        let rootRecognizer = InteractiveContainerPanGestureRecognizer()
        rootNavigationController.view.addGestureRecognizer(rootRecognizer)
        let rootPopGesture = try #require(rootNavigationController.interactivePopGestureRecognizer)

        #expect(
            !rootRecognizer.gestureRecognizer(
                rootRecognizer,
                shouldRequireFailureOf: rootPopGesture
            )
        )
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

    func showFirstPage() {
        pageViewController.setViewControllers(
            [pages[0]],
            direction: .forward,
            animated: false
        )
        pageViewController.view.layoutIfNeeded()
    }

    func showLastPage() {
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
