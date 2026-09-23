import UIKit

@MainActor
final class SidebarPresentationController: UIPresentationController {
    private let motion: SidebarPresentationMotion
    private let dimmingView = DimmingView()
    private let dismissPanGesture = UIPanGestureRecognizer()

    var onDismissGesture: ((UIPanGestureRecognizer) -> Void)?
    var onVisibilityWillChange: ((Bool) -> Void)?
    var onVisibilityChanged: ((Bool) -> Void)?

    init(
        presentedViewController: UIViewController,
        presenting presentingViewController: UIViewController?,
        sidebarWidth: CGFloat
    ) {
        motion = SidebarPresentationMotion(sidebarWidth: sidebarWidth)
        super
            .init(
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
        return motion.sidebarFrame(
            progress: 1,
            in: containerView.bounds
        )
    }

    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        dimmingView.frame = containerView?.bounds ?? .zero
        presentedView?.frame = frameOfPresentedViewInContainerView
    }

    override func presentationTransitionWillBegin() {
        guard let containerView else { return }

        onVisibilityWillChange?(true)
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
            onVisibilityChanged?(false)
            dimmingView.removeFromSuperview()
            return
        }

        onVisibilityChanged?(true)
        containerView?.addGestureRecognizer(dismissPanGesture)
    }

    override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()

        onVisibilityWillChange?(false)

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
            onVisibilityChanged?(false)
            containerView?.removeGestureRecognizer(dismissPanGesture)
            dimmingView.removeFromSuperview()
        } else {
            onVisibilityChanged?(true)
            dimmingView.alpha = 1
        }
    }

    @objc
    private func onDismissPan(_ gesture: UIPanGestureRecognizer) {
        onDismissGesture?(gesture)
    }
}
