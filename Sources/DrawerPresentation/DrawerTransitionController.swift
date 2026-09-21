import UIKit

@MainActor
public final class DrawerTransitionController: NSObject, UIViewControllerTransitioningDelegate {
    public static let defaultDrawerWidth: CGFloat = 320

    let drawerWidth: CGFloat
    /// Whether the presenting view moves to the right while the drawer is shown.
    public var movesPresentingView: Bool
    var animator: DrawerTransitionAnimator? = nil
    var interactiveTransition: UIPercentDrivenInteractiveTransition? = nil

    public init(drawerWidth: CGFloat = 320, movesPresentingView: Bool = true) {
        self.drawerWidth = drawerWidth
        self.movesPresentingView = movesPresentingView
    }

    public func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> (any UIViewControllerAnimatedTransitioning)? {
        let animator = DrawerTransitionAnimator(
            drawerWidth: drawerWidth,
            movesPresentingView: movesPresentingView
        )
        animator.onAnimationEnded = { [weak self] _ in
            self?.interactiveTransition = nil
        }
        animator.isInteractiveTransition = interactiveTransition != nil
        animator.isPresenting = true
        self.animator = animator
        return animator
    }

    public func presentationController(
        forPresented presented: UIViewController,
        presenting: UIViewController?,
        source: UIViewController
    ) -> UIPresentationController? {
        let presentationController = DrawerPresentationController(
            presentedViewController: presented,
            presenting: presenting,
            drawerWidth: drawerWidth
        )
        presentationController.onDismissGesture = { [weak self, weak presented] gesture in
            self?.handleDismissGesture(gesture, presented: presented)
        }
        return presentationController
    }

    public func interactionControllerForPresentation(
        using animator: any UIViewControllerAnimatedTransitioning
    ) -> (any UIViewControllerInteractiveTransitioning)? {
        guard let animator = animator as? DrawerTransitionAnimator,
            animator === self.animator
        else {
            return nil
        }
        return interactiveTransition
    }

    public func animationController(forDismissed dismissed: UIViewController) -> (
        any UIViewControllerAnimatedTransitioning
    )? {
        animator?.isPresenting = false
        animator?.isInteractiveTransition = interactiveTransition != nil
        return animator
    }

    public func interactionControllerForDismissal(
        using animator: any UIViewControllerAnimatedTransitioning
    ) -> (any UIViewControllerInteractiveTransitioning)? {
        guard let animator = animator as? DrawerTransitionAnimator,
            animator === self.animator
        else {
            return nil
        }
        return interactiveTransition
    }

    private func handleDismissGesture(
        _ gesture: UIPanGestureRecognizer,
        presented: UIViewController?
    ) {
        let width = max(drawerWidth, 1)
        let translation = gesture.translation(in: gesture.view).x
        let fractionCompleted = min(max(-translation / width, 0), 1)

        switch gesture.state {
        case .began:
            guard interactiveTransition == nil, let presented else { return }

            let interaction = UIPercentDrivenInteractiveTransition()
            interaction.completionCurve = .easeOut
            interactiveTransition = interaction
            presented.dismiss(animated: true)

        case .changed:
            interactiveTransition?.update(fractionCompleted)

        case .ended:
            guard let interactiveTransition else { return }
            let velocity = gesture.velocity(in: gesture.view).x
            if velocity < 0 || fractionCompleted >= 0.5 {
                interactiveTransition.finish()
            } else {
                interactiveTransition.cancel()
            }

        case .cancelled, .failed:
            interactiveTransition?.cancel()

        default:
            break
        }
    }
}
