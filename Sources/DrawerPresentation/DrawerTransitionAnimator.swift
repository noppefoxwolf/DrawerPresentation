import UIKit

@MainActor
final class DrawerTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let drawerWidth: CGFloat
    let movesPresentingView: Bool
    var isPresenting: Bool = true
    var onAnimationEnded: ((Bool) -> Void)?
    
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
        guard let fromViewController = transitionContext.viewController(forKey: .from),
              let toViewController = transitionContext.viewController(forKey: .to),
              let fromView = fromViewController.view,
              let toView = toViewController.view else {
            transitionContext.completeTransition(false)
            return
        }

        if isPresenting {
            animatePresentation(
                fromView: fromView,
                toView: toView,
                toViewController: toViewController,
                using: transitionContext
            )
        } else {
            animateDismissal(
                fromView: fromView,
                toView: toView,
                using: transitionContext
            )
        }
    }

    func animationEnded(_ transitionCompleted: Bool) {
        onAnimationEnded?(transitionCompleted)
    }

    private func animatePresentation(
        fromView: UIView,
        toView: UIView,
        toViewController: UIViewController,
        using transitionContext: any UIViewControllerContextTransitioning
    ) {
        let containerView = transitionContext.containerView
        if toView.superview !== containerView {
            containerView.addSubview(toView)
        }
        toView.frame = transitionContext.finalFrame(for: toViewController)
        toView.transform = CGAffineTransform(translationX: -drawerWidth, y: 0)

        let animations = {
            toView.transform = .identity
            if self.movesPresentingView {
                // Workaround: view.transform can interfere with SwiftUI gestures.
                fromView.layer.transform = CATransform3DMakeTranslation(self.drawerWidth, 0, 0)
            }
        }

        guard transitionContext.isAnimated else {
            animations()
            transitionContext.completeTransition(true)
            return
        }

        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: 0,
            options: .curveEaseOut,
            animations: animations,
            completion: { [weak self] _ in
                let cancelled = transitionContext.transitionWasCancelled
                if cancelled {
                    toView.transform = .identity
                    if self?.movesPresentingView == true {
                        fromView.layer.transform = CATransform3DIdentity
                    }
                    toView.removeFromSuperview()
                }
                transitionContext.completeTransition(!cancelled)
            }
        )
    }

    private func animateDismissal(
        fromView: UIView,
        toView: UIView,
        using transitionContext: any UIViewControllerContextTransitioning
    ) {
        let animations = {
            fromView.transform = CGAffineTransform(translationX: -self.drawerWidth, y: 0)
            if self.movesPresentingView {
                toView.layer.transform = CATransform3DIdentity
            }
        }

        guard transitionContext.isAnimated else {
            animations()
            fromView.removeFromSuperview()
            transitionContext.completeTransition(true)
            return
        }

        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: 0,
            options: .curveEaseOut,
            animations: animations,
            completion: { [weak self] _ in
                let cancelled = transitionContext.transitionWasCancelled
                if cancelled {
                    fromView.transform = .identity
                    if self?.movesPresentingView == true {
                        toView.layer.transform = CATransform3DMakeTranslation(self?.drawerWidth ?? 0, 0, 0)
                    }
                } else {
                    fromView.removeFromSuperview()
                }
                transitionContext.completeTransition(!cancelled)
            }
        )
    }
}
