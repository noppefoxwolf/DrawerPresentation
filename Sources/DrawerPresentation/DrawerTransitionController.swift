import UIKit

public final class DrawerTransitionController: NSObject, UIViewControllerTransitioningDelegate {
    let drawerWidth: CGFloat
    var animator: DrawerTransitionAnimator? = nil
    var interactiveTransition: UIPercentDrivenInteractiveTransition? = UIPercentDrivenInteractiveTransition()
    
    public init(drawerWidth: CGFloat) {
        self.drawerWidth = drawerWidth
        interactiveTransition?.completionCurve = .linear
        interactiveTransition?.update(0)
    }
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> (any UIViewControllerAnimatedTransitioning)? {
        let animator = DrawerTransitionAnimator(drawerWidth: drawerWidth)
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
