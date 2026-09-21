import InteractiveContainerPanGestureRecognizer
import UIKit

@MainActor
open class SidebarInteraction: NSObject, UIInteraction {
    public weak var delegate: (any SidebarInteractionDelegate)? = nil

    public var isEnabled: Bool = true {
        didSet {
            presentPanGesture.isEnabled = isEnabled
        }
    }

    /// Whether the presenting view moves to the right while the sidebar is shown.
    public var movesPresentingView = false

    let presentPanGesture = InteractiveContainerPanGestureRecognizer()

    var transitionController: SidebarTransitionController? = nil

    public init(delegate: any SidebarInteractionDelegate) {
        self.delegate = delegate
        super.init()
        presentPanGesture.addTarget(self, action: #selector(onPan))
    }

    public weak var view: UIView? = nil

    public func willMove(to view: UIView?) {
        self.view?.removeGestureRecognizer(presentPanGesture)
    }

    public func didMove(to view: UIView?) {
        self.view = view
        presentPanGesture.maximumNumberOfTouches = 1
        presentPanGesture.isEnabled = isEnabled
        view?.addGestureRecognizer(presentPanGesture)
    }

    public func present() {
        present(isInteractiveTransitionEnabled: false)
    }

    private func present(isInteractiveTransitionEnabled: Bool) {
        guard let parent = delegate?.viewController(for: self) else { return }
        guard let vc = delegate?.sidebarInteraction(self, presentingViewControllerFor: parent) else {
            return
        }
        let sidebarWidth =
            delegate?.sidebarInteraction(self, widthForSidebar: vc)
            ?? SidebarTransitionController.defaultSidebarWidth
        transitionController = SidebarTransitionController(
            sidebarWidth: sidebarWidth,
            movesPresentingView: movesPresentingView
        )
        if isInteractiveTransitionEnabled {
            transitionController?.interactiveTransition = UIPercentDrivenInteractiveTransition()
        }
        vc.modalPresentationStyle = .custom
        vc.transitioningDelegate = transitionController
        vc.traitOverrides.userInterfaceLevel = .elevated
        parent.present(vc, animated: true)
    }

    @objc
    private func onPan(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            if transitionController?.interactiveTransition == nil {
                present(isInteractiveTransitionEnabled: true)
                transitionController?.interactiveTransition?.completionCurve = .easeOut
            }

        case .changed:
            if transitionController?.interactiveTransition == nil {
                return
            }

            let x = gesture.translation(in: gesture.view).x
            let width = max(
                transitionController?.sidebarWidth ?? SidebarTransitionController.defaultSidebarWidth,
                1
            )
            let fractionCompleted = min(max(x / width, 0), 1)
            transitionController?.interactiveTransition?.update(fractionCompleted)

        case .ended:
            guard let interactiveTransition = transitionController?.interactiveTransition else {
                return
            }

            let width = max(
                transitionController?.sidebarWidth ?? SidebarTransitionController.defaultSidebarWidth,
                1
            )
            let x = gesture.translation(in: gesture.view).x
            let fractionCompleted = min(max(x / width, 0), 1)
            if gesture.velocity(in: gesture.view).x > 0 || fractionCompleted >= 0.5 {
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
}
