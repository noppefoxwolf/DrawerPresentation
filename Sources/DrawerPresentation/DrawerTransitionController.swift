import UIKit

public final class DrawerTransitionController: NSObject, UIViewControllerTransitioningDelegate {
    let drawerWidth: CGFloat
    var animator: DrawerTransitionAnimator? = nil
    var interactiveTransition: UIPercentDrivenInteractiveTransition? = nil
    
    public init(drawerWidth: CGFloat) {
        self.drawerWidth = drawerWidth
    }
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> (any UIViewControllerAnimatedTransitioning)? {
        let animator = DrawerTransitionAnimator(drawerWidth: drawerWidth)
        animator.isInteractiveTransition = interactiveTransition != nil
        animator.dimmingTapInteraction = TapActionInteraction(action: { [weak presented] in
            presented?.dismiss(animated: true)
        })
        animator.onDismissGesture = { [weak self, weak presented] (gesture, drawerWidth) in
            guard let self else { return }
            switch gesture.state {
            case .began:
                self.interactiveTransition = UIPercentDrivenInteractiveTransition()
                self.interactiveTransition?.completionCurve = .easeOut
                presented?.dismiss(animated: true)
            case .changed:
                let x = gesture.translation(in: gesture.view).x
                let percentComplete = -min(x / drawerWidth, 0)
                self.interactiveTransition?.update(percentComplete)
            case .ended:
                let velocity = gesture.velocity(in: gesture.view).x
                self.setInteractiveSpring(progressVelocity: -velocity / drawerWidth)
                if velocity < 0 {
                    self.interactiveTransition?.finish()
                } else {
                    self.interactiveTransition?.cancel()
                }
                self.interactiveTransition = nil
            case .cancelled:
                let velocity = gesture.velocity(in: gesture.view).x
                self.setInteractiveSpring(progressVelocity: -velocity / drawerWidth)
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
        animator?.isInteractiveTransition = interactiveTransition != nil
        return animator
    }

    func setInteractiveSpring(progressVelocity: CGFloat) {
        let normalizedVelocity = min(max(progressVelocity, -3), 3)
        interactiveTransition?.timingCurve = UISpringTimingParameters(
            dampingRatio: 0.88,
            initialVelocity: CGVector(dx: normalizedVelocity, dy: 0)
        )
    }
    
    public func interactionControllerForDismissal(using animator: any UIViewControllerAnimatedTransitioning) -> (any UIViewControllerInteractiveTransitioning)? {
        if animator is DrawerTransitionAnimator {
            return interactiveTransition
        } else {
            return nil
        }
    }
}
