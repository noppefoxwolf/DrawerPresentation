import UIKit
import SwiftUI
import DrawerPresentation

final class PageViewController: UIPageViewController, UIPageViewControllerDataSource {
    let drawerTransitionController = DrawerTransitionController()
    
    var _viewControllers: [UIViewController] = [
        UIHostingController(rootView: Color.red),
        UIHostingController(rootView: Color.blue),
        UIHostingController(rootView: Color.yellow),
        UIHostingController(rootView: Color.green),
        UIHostingController(rootView: Color.cyan),
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        setViewControllers([_viewControllers[0]], direction: .forward, animated: false)
        
        drawerTransitionController.addDrawerGesture(to: self, drawerViewController: {
            UIHostingController(rootView: Text("Hello, World!"))
        })
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let index = _viewControllers.firstIndex(where: { $0 == viewController })
        guard let index else { return nil }
        guard index != 0 else { return nil }
        return _viewControllers[index - 1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let index = _viewControllers.firstIndex(where: { $0 == viewController })
        guard let index else { return nil }
        guard index != _viewControllers.count - 1 else { return nil }
        return _viewControllers[index + 1]
    }
    
}
