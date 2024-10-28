import UIKit

@MainActor
public protocol DrawerInteractionDelegate: AnyObject, Sendable {
    func drawerInteraction(_ interaction: DrawerInteraction, widthForDrawer drawerViewController: UIViewController) -> CGFloat
    func drawerInteraction(_ interaction: DrawerInteraction, presentingViewControllerFor viewController: UIViewController) -> UIViewController?
    func viewController(for interaction: DrawerInteraction) -> UIViewController
}

@MainActor
public final class DrawerInteraction: NSObject, UIInteraction {
    weak var delegate: DrawerInteractionDelegate? = nil
    let presentPanGesture = UIPanGestureRecognizer()
    let presentSwipeGesture = UISwipeGestureRecognizer()
    
    var interactiveTransition: UIPercentDrivenInteractiveTransition? = nil
    var animator: DrawerTransitionAnimator? = nil
    
    var cancellableGestures: [CancellableGestureWeakBox] = []
    
    public init(delegate: DrawerInteractionDelegate) {
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
    
    public func performInteraction() {
        guard let parent = delegate?.viewController(for: self) else { return }
        guard let vc = delegate?.drawerInteraction(self, presentingViewControllerFor: parent) else { return }
        #if os(iOS)
        vc.modalPresentationStyle = .custom
        vc.transitioningDelegate = self
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
            if interactiveTransition == nil {
                // delay to begin
                interactiveTransition = UIPercentDrivenInteractiveTransition()
                interactiveTransition?.completionCurve = .linear
                performInteraction()
                interactiveTransition?.update(0)
                
                cancellableGestures.compactMap(\.gestureRecognizer).forEach { gestureRecognizer in
                    gestureRecognizer.state = .cancelled
                }
            } else {
                let x = gesture.translation(in: gesture.view).x
                let presentedViewController = delegate?.viewController(for: self)
                let width = presentedViewController.map { delegate?.drawerInteraction(self, widthForDrawer: $0) }?.flatMap({ $0 }) ?? 300.0
                let percentComplete = max(x / width, 0)
                interactiveTransition?.update(percentComplete)
            }
        case .ended:
            if gesture.velocity(in: gesture.view).x > 0 {
                interactiveTransition?.finish()
            } else {
                interactiveTransition?.cancel()
            }
            interactiveTransition = nil
            cancellableGestures.removeAll()
        case .cancelled:
            interactiveTransition?.cancel()
            interactiveTransition = nil
            cancellableGestures.removeAll()
        default:
            break
        }
    }
}

extension DrawerInteraction: UIViewControllerTransitioningDelegate {
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> (any UIViewControllerAnimatedTransitioning)? {
        let animator = DrawerTransitionAnimator(drawerWidth: delegate?.drawerInteraction(self, widthForDrawer: presenting) ?? 300)
        animator.onTapDimmingView = { [weak presented] in presented?.dismiss(animated: true) }
        animator.onDismissGesture = { [weak presented] (gesture, drawerWidth) in
            switch gesture.state {
            case .began:
                self.interactiveTransition = UIPercentDrivenInteractiveTransition()
                self.interactiveTransition?.completionCurve = .linear
                presented?.dismiss(animated: true)
            case .changed:
                let x = gesture.translation(in: gesture.view).x
                let percentComplete = -min(x / drawerWidth, 0)
                self.interactiveTransition?.update(percentComplete)
            case .ended:
                if gesture.velocity(in: gesture.view).x < 0 {
                    self.interactiveTransition?.finish()
                } else {
                    self.interactiveTransition?.cancel()
                }
                self.interactiveTransition = nil
            case .cancelled:
                self.interactiveTransition?.cancel()
                self.interactiveTransition = nil
            default:
                break
            }
        }
        animator.isPresenting = true
        self.animator = animator
        return animator
    }
    
    public func interactionControllerForPresentation(using animator: any UIViewControllerAnimatedTransitioning) -> (any UIViewControllerInteractiveTransitioning)? {
        if animator is DrawerTransitionAnimator {
            return interactiveTransition
        } else {
            return nil
        }
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> (any UIViewControllerAnimatedTransitioning)? {
        animator?.isPresenting = false
        return animator
    }
    
    public func interactionControllerForDismissal(using animator: any UIViewControllerAnimatedTransitioning) -> (any UIViewControllerInteractiveTransitioning)? {
        if animator is DrawerTransitionAnimator {
            return interactiveTransition
        } else {
            return nil
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
