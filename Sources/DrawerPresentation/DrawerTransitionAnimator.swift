import UIKit

@MainActor
final class DrawerTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let drawerWidth: Double
    var isPresenting: Bool = true
    var isInteractiveTransition: Bool = false
    let dimmingView = DimmingView()
    let dismissPanGesture = UIPanGestureRecognizer()

    private var transitionAnimator: UIViewPropertyAnimator?
    private var hasPreparedTransition = false
    
    var dimmingTapInteraction: TapActionInteraction? {
        didSet {
            if let oldValue {
                dimmingView.removeInteraction(oldValue)
            }
            if let interaction = dimmingTapInteraction {
                dimmingView.addInteraction(interaction)
            }
        }
    }
    
    var onDismissGesture: ((_ dismissPanGesture: UIPanGestureRecognizer, _ drawerWidth: CGFloat) -> Void)? = nil
    
    init(drawerWidth: CGFloat) {
        self.drawerWidth = drawerWidth
        super.init()
        dismissPanGesture.addTarget(self, action: #selector(onDismissPan))
    }
    
    deinit {
        // https://forums.swift.org/t/cleaning-up-in-deinit-with-self-and-complete-concurrency-checking/70012/3
        MainActor.assumeIsolated {
            dismissPanGesture.removeTarget(self, action: #selector(onDismissPan))
        }
    }
    
    @objc func onDismissPan(_ dismissPanGesture: UIPanGestureRecognizer) {
        onDismissGesture?(dismissPanGesture, drawerWidth)
    }
    
    func transitionDuration(
        using transitionContext: (any UIViewControllerContextTransitioning)?
    ) -> TimeInterval {
        CATransaction.animationDuration()
    }
    
    func animateTransition(
        using transitionContext: any UIViewControllerContextTransitioning
    ) {
        prepareTransition(using: transitionContext)
        interruptibleAnimator(using: transitionContext).startAnimation()
    }

    func interruptibleAnimator(
        using transitionContext: any UIViewControllerContextTransitioning
    ) -> any UIViewImplicitlyAnimating {
        prepareTransition(using: transitionContext)

        if let transitionAnimator {
            return transitionAnimator
        }

        let fromView = transitionContext.viewController(forKey: .from)?.view
        let toView = transitionContext.viewController(forKey: .to)?.view

        guard let fromView, let toView else {
            return UIViewPropertyAnimator(duration: 0, curve: .linear)
        }

        let drawerWidth = self.drawerWidth
        let dimmingView = self.dimmingView
        let isPresenting = self.isPresenting
        let animations = {
            if isPresenting {
                dimmingView.alpha = 1
                toView.transform = .identity
                // workaround: view.transform hangs SwiftUI gesture. use layer.transform instead view.transform.
                fromView.layer.transform = CATransform3DMakeTranslation(drawerWidth, 0, 0)
            } else {
                dimmingView.alpha = 0
                toView.transform = .identity
                // workaround: view.transform hangs SwiftUI gesture. use layer.transform instead view.transform.
                fromView.layer.transform = CATransform3DMakeTranslation(-drawerWidth, 0, 0)
            }
        }

        let animator: UIViewPropertyAnimator
        if isInteractiveTransition {
            animator = UIViewPropertyAnimator(
                duration: transitionDuration(using: transitionContext),
                curve: .linear,
                animations: animations
            )
        } else {
            animator = UIViewPropertyAnimator(
                duration: transitionDuration(using: transitionContext),
                curve: .easeOut,
                animations: animations
            )
        }

        animator.addCompletion { [weak self, dimmingView, dismissPanGesture] _ in
            guard let self else { return }

            if isPresenting {
                if transitionContext.transitionWasCancelled {
                    fromView.layer.transform = CATransform3DIdentity
                    dimmingView.removeFromSuperview()
                    toView.removeFromSuperview()
                } else {
                    transitionContext.containerView.addGestureRecognizer(dismissPanGesture)
                }
            } else if transitionContext.transitionWasCancelled {
                fromView.layer.transform = CATransform3DIdentity
                dimmingView.alpha = 1
            } else {
                fromView.removeFromSuperview()
                dimmingView.removeFromSuperview()
                transitionContext.containerView.removeGestureRecognizer(dismissPanGesture)
            }

            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            self.transitionAnimator = nil
            self.hasPreparedTransition = false
        }

        transitionAnimator = animator
        return animator
    }

    private func prepareTransition(
        using transitionContext: any UIViewControllerContextTransitioning
    ) {
        guard !hasPreparedTransition else { return }

        guard let fromView = transitionContext.viewController(forKey: .from)?.view,
              let toView = transitionContext.viewController(forKey: .to)?.view else {
            return
        }

        if isPresenting {
            transitionContext.containerView.addSubview(dimmingView)
            dimmingView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                dimmingView.topAnchor.constraint(equalTo: transitionContext.containerView.topAnchor),
                transitionContext.containerView.bottomAnchor.constraint(equalTo: dimmingView.bottomAnchor),
                dimmingView.leadingAnchor.constraint(equalTo: transitionContext.containerView.leadingAnchor),
                transitionContext.containerView.trailingAnchor.constraint(equalTo: dimmingView.trailingAnchor),
            ])

            transitionContext.containerView.addSubview(toView)
            toView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                toView.leftAnchor.constraint(equalTo: transitionContext.containerView.leftAnchor),
                toView.topAnchor.constraint(equalTo: transitionContext.containerView.topAnchor),
                toView.bottomAnchor.constraint(equalTo: transitionContext.containerView.bottomAnchor),
                toView.widthAnchor.constraint(equalToConstant: drawerWidth)
            ])
            toView.transform = CGAffineTransform(translationX: -drawerWidth, y: 0)
            dimmingView.alpha = 0
        }

        hasPreparedTransition = true
    }
}
