import UIKit

@MainActor
final class DrawerPresentationController: UIPresentationController {
    private let drawerWidth: CGFloat
    private let dimmingView = DimmingView()
    private let dismissPanGesture = UIPanGestureRecognizer()

    var onDismissGesture: ((UIPanGestureRecognizer) -> Void)?

    init(
        presentedViewController: UIViewController,
        presenting presentingViewController: UIViewController?,
        drawerWidth: CGFloat
    ) {
        self.drawerWidth = drawerWidth
        super.init(
            presentedViewController: presentedViewController,
            presenting: presentingViewController
        )

        dismissPanGesture.addTarget(self, action: #selector(onDismissPan))
        dimmingView.addInteraction(
            TapActionInteraction(action: { [weak presentedViewController] in
                presentedViewController?.dismiss(animated: true)
            })
        )
    }

    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView else { return .zero }
        return CGRect(
            x: containerView.bounds.minX,
            y: containerView.bounds.minY,
            width: drawerWidth,
            height: containerView.bounds.height
        )
    }

    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        dimmingView.frame = containerView?.bounds ?? .zero
        presentedView?.frame = frameOfPresentedViewInContainerView
    }

    override func presentationTransitionWillBegin() {
        guard let containerView else { return }

        dimmingView.frame = containerView.bounds
        dimmingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        dimmingView.alpha = 0
        containerView.insertSubview(dimmingView, at: 0)

        guard let coordinator = presentedViewController.transitionCoordinator else {
            dimmingView.alpha = 1
            return
        }

        coordinator.animate(alongsideTransition: { [weak self] _ in
            self?.dimmingView.alpha = 1
        })
    }

    override func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed)
        guard completed else {
            dimmingView.removeFromSuperview()
            return
        }

        containerView?.addGestureRecognizer(dismissPanGesture)
    }

    override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()

        guard let coordinator = presentedViewController.transitionCoordinator else {
            dimmingView.alpha = 0
            return
        }

        coordinator.animate(alongsideTransition: { [weak self] _ in
            self?.dimmingView.alpha = 0
        })
    }

    override func dismissalTransitionDidEnd(_ completed: Bool) {
        super.dismissalTransitionDidEnd(completed)

        if completed {
            containerView?.removeGestureRecognizer(dismissPanGesture)
            dimmingView.removeFromSuperview()
        } else {
            dimmingView.alpha = 1
        }
    }

    @objc
    private func onDismissPan(_ gesture: UIPanGestureRecognizer) {
        onDismissGesture?(gesture)
    }
}
