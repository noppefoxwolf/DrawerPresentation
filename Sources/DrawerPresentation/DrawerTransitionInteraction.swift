import UIKit

@MainActor
open class DrawerInteraction: NSObject, UIInteraction {
    public weak var delegate: (any DrawerInteractionDelegate)? = nil
    
    let presentPanGesture = UIPanGestureRecognizer()
    let presentSwipeGesture = UISwipeGestureRecognizer()
    var cancellableGestures: [CancellableGestureWeakBox] = []
    
    var transitionController: DrawerTransitionController? = nil
    
    public init(delegate: any DrawerInteractionDelegate) {
        self.delegate = delegate
        super.init()
    }
    
    public weak var view: UIView? = nil
    
    public func willMove(to view: UIView?) {
        self.view = view
    }
    
    public func didMove(to view: UIView?) {
        #if os(iOS)
        presentPanGesture.delegate = self
        presentPanGesture.addTarget(self, action: #selector(onPan))
        presentPanGesture.maximumNumberOfTouches = 1
        view?.addGestureRecognizer(presentPanGesture)

        presentSwipeGesture.delegate = self
        presentSwipeGesture.direction = .right
        view?.addGestureRecognizer(presentSwipeGesture)
        #endif
    }
    
    public func present() {
        present(isInteractiveTransitoionEnabled: false)
    }
    
    private func present(isInteractiveTransitoionEnabled: Bool) {
        guard let parent = delegate?.viewController(for: self) else { return }
        guard let vc = delegate?.drawerInteraction(self, presentingViewControllerFor: parent) else { return }
        let drawerWidth = delegate?.drawerInteraction(self, widthForDrawer: vc) ?? 300
        transitionController = DrawerTransitionController(drawerWidth: drawerWidth)
        if isInteractiveTransitoionEnabled {
            transitionController?.interactiveTransition = UIPercentDrivenInteractiveTransition()
        }
        #if os(iOS)
        vc.modalPresentationStyle = .custom
        vc.transitioningDelegate = transitionController
        #endif
        if #available(iOS 17.0, *) {
            vc.traitOverrides.userInterfaceLevel = .elevated
        }
        parent.present(vc, animated: true)
    }
    
    @objc
    private func onPan(_ gesture: UIPanGestureRecognizer) {
        guard presentSwipeGesture.state == .ended else { return }
        switch gesture.state {
        case .began:
            break
        case .changed:
            if transitionController?.interactiveTransition == nil {
                present(isInteractiveTransitoionEnabled: true)
                transitionController?.interactiveTransition?.completionCurve = .linear
                transitionController?.interactiveTransition?.update(0)
                // delay to begin
                cancellableGestures.compactMap(\.gestureRecognizer).forEach { gestureRecognizer in
                    gestureRecognizer.state = .cancelled
                }
            } else {
                let x = gesture.translation(in: gesture.view).x
                let presentedViewController = delegate?.viewController(for: self)
                let width = presentedViewController.map { delegate?.drawerInteraction(self, widthForDrawer: $0) }?.flatMap({ $0 }) ?? 300.0
                let percentComplete = max(x / width, 0)
                transitionController?.interactiveTransition?.update(percentComplete)
            }
        case .ended:
            if gesture.velocity(in: gesture.view).x > 0 {
                transitionController?.interactiveTransition?.finish()
            } else {
                transitionController?.interactiveTransition?.cancel()
            }
            transitionController?.interactiveTransition = nil
            cancellableGestures.removeAll()
        case .cancelled:
            transitionController?.interactiveTransition?.cancel()
            transitionController?.interactiveTransition = nil
            cancellableGestures.removeAll()
        default:
            break
        }
    }
}

extension DrawerInteraction: UIGestureRecognizerDelegate {
    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        // enable multiple gesture
        if gestureRecognizer == presentPanGesture && otherGestureRecognizer == presentSwipeGesture {
            return true
        }
        
        let scrollView = otherGestureRecognizer.view as? UIScrollView
        guard let scrollView else { return false }
                
        // Save gestureRecognizer reference for lazy cancel
        if otherGestureRecognizer.view is UIScrollView {
            let box = CancellableGestureWeakBox(otherGestureRecognizer)
            cancellableGestures.append(box)
        }
        
        /* Enable only on left */
        
        // Special case 1: _UIQueuingScrollView always centered offset.
        if String(describing: type(of: scrollView)) == "_UIQueuingScrollView" {
            let isItemFit = scrollView.contentOffset.x == scrollView.bounds.width
            let isLeft = scrollView.adjustedContentInset.left <= 0
            return isItemFit && isLeft
        }
        
        return scrollView.contentOffset.x <= 0
    }
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let parent = delegate?.viewController(for: self)
        if gestureRecognizer == presentSwipeGesture {
            let navigating: Bool
            if let nc = parent as? UINavigationController {
                navigating = nc.viewControllers.count > 1
            } else if let nc = parent?.navigationController {
                navigating = nc.viewControllers.count > 1
            } else if let nc = (parent as? UITabBarController)?.selectedViewController as? UINavigationController {
                navigating = nc.viewControllers.count > 1
            } else {
                navigating = false
            }
            if navigating {
                return false
            }
        }
        return true
    }
}
