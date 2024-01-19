import UIKit

public struct DrawerTransitionConfiguration {
    public var drawerWidth: Double = 300
    
    public static var `default`: DrawerTransitionConfiguration { .init() }
}

public final class DrawerTransitionController: NSObject {
    let configuration: DrawerTransitionConfiguration
    let presentPanGesture = UIPanGestureRecognizer()
    let presentSwipeGesture = UISwipeGestureRecognizer()
    
    var interactiveTransition: UIPercentDrivenInteractiveTransition? = nil
    let animator: DrawerTransitionAnimator
    
    weak var parent: UIViewController? = nil
    var makeViewController: () -> UIViewController = { preconditionFailure("No ViewController registered.") }
    
    var cancellableGestures: [CancellableGestureWeakBox] = []
    
    public init(_ configuration: DrawerTransitionConfiguration = .default) {
        self.configuration = configuration
        self.animator = DrawerTransitionAnimator(drawerWidth: configuration.drawerWidth)
        super.init()
    }
    
    public func addDrawerGesture(to viewController: UIViewController, drawerViewController: @escaping () -> UIViewController) {
        parent = viewController
        
        presentPanGesture.delegate = self
        presentPanGesture.addTarget(self, action: #selector(onPan))
        presentPanGesture.maximumNumberOfTouches = 1
        viewController.view.addGestureRecognizer(presentPanGesture)
        
        presentSwipeGesture.delegate = self
        presentSwipeGesture.direction = .right
        viewController.view.addGestureRecognizer(presentSwipeGesture)
        
        makeViewController = drawerViewController
    }
    
    public func presentRegisteredDrawer() {
        let vc = makeViewController()
        vc.modalPresentationStyle = .custom
        vc.transitioningDelegate = self
        parent?.present(vc, animated: true)
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
                interactiveTransition?.completionCurve = .easeOut
                presentRegisteredDrawer()
                
                cancellableGestures.compactMap(\.gestureRecognizer).forEach { gestureRecognizer in
                    gestureRecognizer.state = .cancelled
                }
            } else {
                let x = gesture.translation(in: gesture.view).x
                let percentComplete = max(x / animator.drawerWidth, 0)
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

extension DrawerTransitionController: UIViewControllerTransitioningDelegate {
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> (any UIViewControllerAnimatedTransitioning)? {
        animator.onTapDimmingView = { presented.dismiss(animated: true) }
        animator.onDismissGesture = { [weak presented] gesture in
            switch gesture.state {
            case .began:
                self.interactiveTransition = UIPercentDrivenInteractiveTransition()
                self.interactiveTransition?.completionCurve = .easeIn
                presented?.dismiss(animated: true)
            case .changed:
                let x = gesture.translation(in: gesture.view).x
                let percentComplete = -min(x / self.animator.drawerWidth, 0)
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
        animator.isPresenting = false
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

extension DrawerTransitionController: UIGestureRecognizerDelegate {
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
}
