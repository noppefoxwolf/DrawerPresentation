import InteractiveContainerPanGestureRecognizer
import UIKit

@MainActor
open class SidebarInteraction: NSObject, UIInteraction {
    public weak var delegate: (any SidebarInteractionDelegate)? = nil

    public var isEnabled: Bool = true {
        didSet {
            updatePresentGestureState()
        }
    }

    public let presentation: SidebarPresentation

    let presentPanGesture = InteractiveContainerPanGestureRecognizer()

    private var transitionController: SidebarTransitionController?
    private var embeddedViewController: SidebarEmbeddedViewController?
    private weak var presentedViewController: UIViewController?

    public init(
        delegate: any SidebarInteractionDelegate,
        presentation: SidebarPresentation = .modal
    ) {
        self.delegate = delegate
        self.presentation = presentation
        super.init()
        presentPanGesture.addTarget(self, action: #selector(onPan))
    }

    public weak var view: UIView? = nil

    public func willMove(to view: UIView?) {
        self.view?.removeGestureRecognizer(presentPanGesture)
        if view == nil {
            removeEmbeddedViewController()
        }
    }

    public func didMove(to view: UIView?) {
        self.view = view
        presentPanGesture.maximumNumberOfTouches = 1
        updatePresentGestureState()
        view?.addGestureRecognizer(presentPanGesture)
    }

    public func present() {
        present(isInteractiveTransitionEnabled: false)
    }

    public func dismiss(animated: Bool = true) {
        switch presentation {
        case .modal:
            presentedViewController?.dismiss(animated: animated)

        case .embedded:
            embeddedViewController?.hide(animated: animated)
        }
    }

    private func present(isInteractiveTransitionEnabled: Bool) {
        guard isEnabled else { return }

        switch presentation {
        case .modal:
            presentModally(isInteractiveTransitionEnabled: isInteractiveTransitionEnabled)

        case .embedded:
            presentAsEmbedded(isInteractiveTransitionEnabled: isInteractiveTransitionEnabled)
        }
    }

    @objc
    private func onPan(_ gesture: UIPanGestureRecognizer) {
        switch presentation {
        case .modal:
            handleModalPan(gesture)
        case .embedded:
            handleEmbeddedPan(gesture)
        }
    }

    private func presentModally(isInteractiveTransitionEnabled: Bool) {
        guard let parent = delegate?.viewController(for: self) else { return }
        guard let vc = delegate?.sidebarInteraction(self, presentingViewControllerFor: parent) else {
            return
        }

        removeEmbeddedViewController()

        let sidebarWidth = width(for: vc)
        let transitionController = SidebarTransitionController(sidebarWidth: sidebarWidth)
        if isInteractiveTransitionEnabled {
            transitionController.interactiveTransition = UIPercentDrivenInteractiveTransition()
        }
        vc.modalPresentationStyle = .custom
        vc.transitioningDelegate = transitionController
        vc.traitOverrides.userInterfaceLevel = .elevated
        self.transitionController = transitionController
        presentedViewController = vc
        parent.present(vc, animated: true)
    }

    private func presentAsEmbedded(isInteractiveTransitionEnabled: Bool) {
        guard let parent = delegate?.viewController(for: self) else { return }

        if let embeddedViewController,
            embeddedViewController.parent === parent
        {
            if isInteractiveTransitionEnabled {
                embeddedViewController.beginInteractivePresentation()
            } else {
                embeddedViewController.show(animated: true)
            }
            updatePresentGestureState()
            return
        }

        removeEmbeddedViewController()

        guard let vc = delegate?.sidebarInteraction(self, presentingViewControllerFor: parent) else {
            return
        }

        let embeddedViewController = SidebarEmbeddedViewController(
            sidebarViewController: vc,
            sidebarWidth: width(for: vc)
        )
        embeddedViewController.onVisibilityChanged = { [weak self] _ in
            self?.updatePresentGestureState()
        }

        parent.addChild(embeddedViewController)
        embeddedViewController.view.frame = parent.view.bounds
        embeddedViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        parent.view.addSubview(embeddedViewController.view)
        embeddedViewController.didMove(toParent: parent)
        self.embeddedViewController = embeddedViewController

        if isInteractiveTransitionEnabled {
            embeddedViewController.beginInteractivePresentation()
        } else {
            embeddedViewController.show(animated: true)
        }
        updatePresentGestureState()
    }

    private func handleModalPan(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            if transitionController?.interactiveTransition == nil {
                presentModally(isInteractiveTransitionEnabled: true)
                transitionController?.interactiveTransition?.completionCurve = .easeOut
            }

        case .changed:
            if transitionController?.interactiveTransition == nil {
                return
            }

            let fractionCompleted = SidebarGestureMetrics.presentationProgress(
                translation: gesture.translation(in: gesture.view).x,
                width: transitionController?.sidebarWidth
                    ?? SidebarTransitionController.defaultSidebarWidth
            )
            transitionController?.interactiveTransition?.update(fractionCompleted)

        case .ended:
            guard let interactiveTransition = transitionController?.interactiveTransition else {
                return
            }

            let fractionCompleted = SidebarGestureMetrics.presentationProgress(
                translation: gesture.translation(in: gesture.view).x,
                width: transitionController?.sidebarWidth
                    ?? SidebarTransitionController.defaultSidebarWidth
            )
            if SidebarGestureMetrics.shouldFinishPresentation(
                velocity: gesture.velocity(in: gesture.view).x,
                progress: fractionCompleted
            ) {
                interactiveTransition.finish()
            } else {
                interactiveTransition.cancel()
            }

        case .cancelled, .failed:
            transitionController?.interactiveTransition?.cancel()

        default:
            break
        }
    }

    private func handleEmbeddedPan(_ gesture: UIPanGestureRecognizer) {
        if embeddedViewController?.isVisible == true {
            return
        }

        switch gesture.state {
        case .began:
            presentAsEmbedded(isInteractiveTransitionEnabled: true)

        case .changed:
            guard let embeddedViewController else { return }

            let fractionCompleted = SidebarGestureMetrics.presentationProgress(
                translation: gesture.translation(in: gesture.view).x,
                width: embeddedViewController.sidebarWidth
            )
            embeddedViewController.updateInteractivePresentation(fractionCompleted)

        case .ended:
            guard let embeddedViewController else { return }

            let fractionCompleted = SidebarGestureMetrics.presentationProgress(
                translation: gesture.translation(in: gesture.view).x,
                width: embeddedViewController.sidebarWidth
            )
            if SidebarGestureMetrics.shouldFinishPresentation(
                velocity: gesture.velocity(in: gesture.view).x,
                progress: fractionCompleted
            ) {
                embeddedViewController.finishInteractivePresentation()
            } else {
                embeddedViewController.cancelInteractivePresentation()
            }

        case .cancelled, .failed:
            embeddedViewController?.cancelInteractivePresentation()

        default:
            break
        }
    }

    private func width(for sidebarViewController: UIViewController) -> CGFloat {
        delegate?.sidebarInteraction(self, widthForSidebar: sidebarViewController)
            ?? SidebarTransitionController.defaultSidebarWidth
    }

    private func updatePresentGestureState() {
        presentPanGesture.isEnabled = isEnabled && embeddedViewController?.isVisible != true
    }

    private func removeEmbeddedViewController() {
        embeddedViewController?.detachFromParent()
        embeddedViewController = nil
        updatePresentGestureState()
    }
}
