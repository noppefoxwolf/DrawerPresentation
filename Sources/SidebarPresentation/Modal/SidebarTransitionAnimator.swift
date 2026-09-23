import UIKit

@MainActor
final class SidebarTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let motion: SidebarPresentationMotion
    var isPresenting: Bool = true
    var isInteractiveTransition = false
    var onAnimationEnded: ((Bool) -> Void)?

    private var transitionAnimator: UIViewPropertyAnimator?
    private var preparedTransitionID: ObjectIdentifier?
    private weak var preparedFromView: UIView?
    private weak var preparedToView: UIView?

    init(sidebarWidth: CGFloat) {
        motion = SidebarPresentationMotion(sidebarWidth: sidebarWidth)
        super.init()
    }

    func transitionDuration(
        using transitionContext: (any UIViewControllerContextTransitioning)?
    ) -> TimeInterval {
        SidebarPresentationMotion.animationDuration
    }

    func animateTransition(
        using transitionContext: any UIViewControllerContextTransitioning
    ) {
        interruptibleAnimator(using: transitionContext).startAnimation()
    }

    func interruptibleAnimator(
        using transitionContext: any UIViewControllerContextTransitioning
    ) -> any UIViewImplicitlyAnimating {
        let transitionID = ObjectIdentifier(transitionContext as AnyObject)
        if preparedTransitionID == transitionID, let transitionAnimator {
            return transitionAnimator
        }

        guard let views = prepareViews(using: transitionContext) else {
            let animator = UIViewPropertyAnimator(duration: 0, curve: .linear)
            animator.addCompletion { [weak self] _ in
                transitionContext.completeTransition(false)
                self?.transitionAnimator = nil
            }
            transitionAnimator = animator
            return animator
        }

        let duration =
            transitionContext.isAnimated
            ? transitionDuration(using: transitionContext)
            : 0
        let curve: UIView.AnimationCurve = isInteractiveTransition
            ? .linear
            : SidebarPresentationMotion.animationCurve
        let isPresenting = self.isPresenting
        let motion = self.motion
        let containerBounds = transitionContext.containerView.bounds

        let animator = UIViewPropertyAnimator(
            duration: duration,
            curve: curve
        ) {
            if isPresenting {
                views.toView.frame = motion.sidebarFrame(
                    progress: 1,
                    in: containerBounds
                )
            } else {
                views.fromView.frame = motion.sidebarFrame(
                    progress: 0,
                    in: containerBounds
                )
            }
        }
        animator.addCompletion { [weak self] (_: UIViewAnimatingPosition) in
            self?
                .completeTransition(
                    transitionContext,
                    fromView: views.fromView,
                    toView: views.toView,
                    isPresenting: isPresenting
                )
        }
        transitionAnimator = animator
        return animator
    }

    func animationEnded(_ transitionCompleted: Bool) {
        transitionAnimator = nil
        preparedTransitionID = nil
        preparedFromView = nil
        preparedToView = nil
        onAnimationEnded?(transitionCompleted)
    }

    private func prepareViews(
        using transitionContext: any UIViewControllerContextTransitioning
    ) -> (fromView: UIView, toView: UIView)? {
        let transitionID = ObjectIdentifier(transitionContext as AnyObject)
        if preparedTransitionID == transitionID,
            let fromView = preparedFromView,
            let toView = preparedToView
        {
            return (fromView, toView)
        }

        preparedTransitionID = transitionID
        preparedFromView = nil
        preparedToView = nil

        guard let fromViewController = transitionContext.viewController(forKey: .from),
            let toViewController = transitionContext.viewController(forKey: .to),
            let fromView = fromViewController.view,
            let toView = toViewController.view
        else {
            return nil
        }

        let containerView = transitionContext.containerView
        if isPresenting {
            if toView.superview !== containerView {
                containerView.addSubview(toView)
            }
            toView.frame = motion.sidebarFrame(progress: 0, in: containerView.bounds)
        } else {
            fromView.frame = transitionContext.initialFrame(for: fromViewController)
        }

        preparedFromView = fromView
        preparedToView = toView
        return (fromView, toView)
    }

    private func completeTransition(
        _ transitionContext: any UIViewControllerContextTransitioning,
        fromView: UIView,
        toView: UIView,
        isPresenting: Bool
    ) {
        let cancelled = transitionContext.transitionWasCancelled
        if cancelled {
            if isPresenting {
                toView.removeFromSuperview()
            } else {
                fromView.frame = motion.sidebarFrame(
                    progress: 1,
                    in: transitionContext.containerView.bounds
                )
            }
        } else if !isPresenting {
            fromView.removeFromSuperview()
        }
        transitionContext.completeTransition(!cancelled)
    }
}
