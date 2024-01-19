import UIKit

final class DrawerTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let drawerWidth: Double
    var isPresenting: Bool = true
    let dimmingView = DimmingView()
    let dismissPanGesture = UIPanGestureRecognizer()
    
    var onTapDimmingView: (() -> Void)? {
        get { dimmingView.onTap }
        set { dimmingView.onTap = newValue }
    }
    
    var onDismissGesture: ((_ dismissPanGesture: UIPanGestureRecognizer) -> Void)? = nil
    
    init(drawerWidth: Double) {
        self.drawerWidth = drawerWidth
        super.init()
        dismissPanGesture.addTarget(self, action: #selector(onDismissPan))
    }
    
    deinit {
        dismissPanGesture.removeTarget(self, action: #selector(onDismissPan))
    }
    
    @objc func onDismissPan(_ dismissPanGesture: UIPanGestureRecognizer) {
        onDismissGesture?(dismissPanGesture)
    }
    
    func transitionDuration(using transitionContext: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
        CATransaction.animationDuration()
    }
    
    func animateTransition(using transitionContext: any UIViewControllerContextTransitioning) {
        if isPresenting {
            animatePresentTransition(using: transitionContext)
        } else {
            dismissPresentTransition(using: transitionContext)
        }
    }
    
    func dismissPresentTransition(using transitionContext: any UIViewControllerContextTransitioning) {
        let fromView = transitionContext.viewController(forKey: .from)?.view
        let toView = transitionContext.viewController(forKey: .to)?.view
        
        guard let fromView, let toView else { return }
                        
        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: 0,
            options: .curveLinear,
            animations: { [dimmingView, drawerWidth] in
                dimmingView.alpha = 0
                toView.transform = .identity
                fromView.transform = CGAffineTransform(translationX: -drawerWidth, y: 0)
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
    
    func animatePresentTransition(using transitionContext: any UIViewControllerContextTransitioning) {
        let fromView = transitionContext.viewController(forKey: .from)?.view
        let toView = transitionContext.viewController(forKey: .to)?.view
        
        guard let fromView, let toView else { return }
        
        transitionContext.containerView.addSubview(dimmingView)
        transitionContext.containerView.addSubview(toView)
        
        toView.frame = CGRect(x: 0, y: 0, width: drawerWidth, height: fromView.bounds.height)
        toView.transform = CGAffineTransform(translationX: -drawerWidth, y: 0)
        dimmingView.alpha = 0
        dimmingView.frame = fromView.bounds
        
        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: 0,
            options: .curveLinear,
            animations: { [dimmingView, drawerWidth] in
                dimmingView.alpha = 1
                toView.transform = .identity
                fromView.transform = CGAffineTransform(translationX: drawerWidth, y: 0)
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
}

