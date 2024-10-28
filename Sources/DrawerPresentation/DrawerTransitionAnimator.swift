import UIKit

@MainActor
final class DrawerTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let drawerWidth: Double
    var isPresenting: Bool = true
    let dimmingView = DimmingView()
    let dismissPanGesture = UIPanGestureRecognizer()
    
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
        if isPresenting {
            animatePresentTransition(using: transitionContext)
        } else {
            dismissPresentTransition(using: transitionContext)
        }
    }
    
    func animatePresentTransition(
        using transitionContext: any UIViewControllerContextTransitioning
    ) {
        let fromView = transitionContext.viewController(forKey: .from)?.view
        let toView = transitionContext.viewController(forKey: .to)?.view
        
        guard let fromView, let toView else { return }
        
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
        
        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: 0,
            options: .curveEaseOut,
            animations: { [dimmingView, drawerWidth] in
                dimmingView.alpha = 1
                toView.transform = .identity
                // workaround: view.transform hangs SwiftUI gesture. use layer.transform instead view.transform.
                fromView.layer.transform = CATransform3DMakeTranslation(drawerWidth, 0, 0)
            },
            completion: { [dimmingView, dismissPanGesture] _ in
                if transitionContext.transitionWasCancelled {
                    dimmingView.removeFromSuperview()
                    toView.removeFromSuperview()
                } else {
                    transitionContext.containerView.addGestureRecognizer(dismissPanGesture)
                }
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        )
    }
    
    func dismissPresentTransition(
        using transitionContext: any UIViewControllerContextTransitioning
    ) {
        let fromView = transitionContext.viewController(forKey: .from)?.view
        let toView = transitionContext.viewController(forKey: .to)?.view
        
        guard let fromView, let toView else { return }
                        
        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: 0,
            options: .curveEaseOut,
            animations: { [dimmingView, drawerWidth] in
                dimmingView.alpha = 0
                toView.transform = .identity
                // workaround: view.transform hangs SwiftUI gesture. use layer.transform instead view.transform.
                fromView.layer.transform = CATransform3DMakeTranslation(-drawerWidth, 0, 0)
            },
            completion: { [dimmingView, dismissPanGesture] _ in
                if transitionContext.transitionWasCancelled {
                } else {
                    fromView.removeFromSuperview()
                    dimmingView.removeFromSuperview()
                    transitionContext.containerView.removeGestureRecognizer(dismissPanGesture)
                }
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        )
    }
}
