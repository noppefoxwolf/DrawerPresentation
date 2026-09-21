import UIKit

@MainActor
final class DrawerTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let drawerWidth: CGFloat
    let movesPresentingView: Bool
    var isPresenting: Bool = true
    var isInteractiveTransition = false
    var onAnimationEnded: ((Bool) -> Void)?

    private var transitionAnimator: UIViewPropertyAnimator?
    private var preparedTransitionID: ObjectIdentifier?
    private weak var preparedFromView: UIView?
    private weak var preparedToView: UIView?
    
    init(drawerWidth: CGFloat, movesPresentingView: Bool) {
        self.drawerWidth = drawerWidth
        self.movesPresentingView = movesPresentingView
        super.init()
    }
    
    func transitionDuration(
        using transitionContext: (any UIViewControllerContextTransitioning)?
    ) -> TimeInterval {
        0.3
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

        let duration = transitionContext.isAnimated
            ? transitionDuration(using: transitionContext)
            : 0
        let curve: UIView.AnimationCurve = isInteractiveTransition ? .linear : .easeOut
        let drawerWidth = self.drawerWidth
        let movesPresentingView = self.movesPresentingView
        let isPresenting = self.isPresenting

        let animator = UIViewPropertyAnimator(
            duration: duration,
            curve: curve
        ) {
            if isPresenting {
                views.toView.transform = .identity
                if movesPresentingView {
                    views.fromView.layer.transform = CATransform3DMakeTranslation(
                        drawerWidth,
                        0,
                        0
                    )
                }
            } else {
                views.fromView.transform = CGAffineTransform(
                    translationX: -drawerWidth,
                    y: 0
                )
                if movesPresentingView {
                    views.toView.layer.transform = CATransform3DIdentity
                }
            }
        }
        animator.addCompletion { [weak self] (_: UIViewAnimatingPosition) in
            self?.completeTransition(
                transitionContext,
                fromView: views.fromView,
                toView: views.toView,
                drawerWidth: drawerWidth,
                movesPresentingView: movesPresentingView,
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
           let toView = preparedToView {
            return (fromView, toView)
        }

        preparedTransitionID = transitionID
        preparedFromView = nil
        preparedToView = nil

        guard let fromViewController = transitionContext.viewController(forKey: .from),
              let toViewController = transitionContext.viewController(forKey: .to),
              let fromView = fromViewController.view,
              let toView = toViewController.view else {
            return nil
        }

        let containerView = transitionContext.containerView
        if isPresenting {
            if toView.superview !== containerView {
                containerView.addSubview(toView)
            }
            toView.frame = transitionContext.finalFrame(for: toViewController)
            toView.transform = CGAffineTransform(translationX: -drawerWidth, y: 0)
        }

        preparedFromView = fromView
        preparedToView = toView
        return (fromView, toView)
    }

    private func completeTransition(
        _ transitionContext: any UIViewControllerContextTransitioning,
        fromView: UIView,
        toView: UIView,
        drawerWidth: CGFloat,
        movesPresentingView: Bool,
        isPresenting: Bool
    ) {
        let cancelled = transitionContext.transitionWasCancelled
        if cancelled {
            if isPresenting {
                toView.transform = .identity
                if movesPresentingView {
                    fromView.layer.transform = CATransform3DIdentity
                }
                toView.removeFromSuperview()
            } else {
                fromView.transform = .identity
                if movesPresentingView {
                    toView.layer.transform = CATransform3DMakeTranslation(
                        drawerWidth,
                        0,
                        0
                    )
                }
            }
        } else if !isPresenting {
            fromView.removeFromSuperview()
        }
        transitionContext.completeTransition(!cancelled)
    }
}
