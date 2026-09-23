import UIKit

@MainActor
public final class SidebarTransitionController: NSObject, UIViewControllerTransitioningDelegate {
    public static let defaultSidebarWidth: CGFloat = 320

    let sidebarWidth: CGFloat
    var animator: SidebarTransitionAnimator? = nil
    var interactiveTransition: UIPercentDrivenInteractiveTransition? = nil

    public init(sidebarWidth: CGFloat = SidebarTransitionController.defaultSidebarWidth) {
        self.sidebarWidth = sidebarWidth
    }

    public func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> (any UIViewControllerAnimatedTransitioning)? {
        let animator = SidebarTransitionAnimator(sidebarWidth: sidebarWidth)
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
        let presentationController = SidebarPresentationController(
            presentedViewController: presented,
            presenting: presenting,
            sidebarWidth: sidebarWidth
        )
        presentationController.onDismissGesture = { [weak self, weak presented] gesture in
            self?.handleDismissGesture(gesture, presented: presented)
        }
        return presentationController
    }

    public func interactionControllerForPresentation(
        using animator: any UIViewControllerAnimatedTransitioning
    ) -> (any UIViewControllerInteractiveTransitioning)? {
        guard let animator = animator as? SidebarTransitionAnimator,
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
        guard let animator = animator as? SidebarTransitionAnimator,
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
        let translation = gesture.translation(in: gesture.view).x
        let fractionCompleted = SidebarGestureMetrics.dismissalProgress(
            translation: translation,
            width: sidebarWidth
        )

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
            if SidebarGestureMetrics.shouldFinishDismissal(
                velocity: velocity,
                progress: fractionCompleted
            ) {
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
