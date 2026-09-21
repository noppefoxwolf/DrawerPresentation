import UIKit
import InteractiveContainerPanGestureRecognizer

@MainActor
open class DrawerInteraction: NSObject, UIInteraction {
    public weak var delegate: (any DrawerInteractionDelegate)? = nil

    public var isEnabled: Bool = true {
        didSet {
            presentPanGesture.isEnabled = isEnabled
        }
    }

    /// Whether the presenting view moves to the right while the drawer is shown.
    public var movesPresentingView = true
    
    let presentPanGesture = InteractiveContainerPanGestureRecognizer()
    
    var transitionController: DrawerTransitionController? = nil
    
    public init(delegate: any DrawerInteractionDelegate) {
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
        guard let vc = delegate?.drawerInteraction(self, presentingViewControllerFor: parent) else { return }
        let drawerWidth = delegate?.drawerInteraction(self, widthForDrawer: vc)
            ?? DrawerTransitionController.defaultDrawerWidth
        transitionController = DrawerTransitionController(
            drawerWidth: drawerWidth,
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
                transitionController?.drawerWidth ?? DrawerTransitionController.defaultDrawerWidth,
                1
            )
            let fractionCompleted = min(max(x / width, 0), 1)
            transitionController?.interactiveTransition?.update(fractionCompleted)

        case .ended:
            guard let interactiveTransition = transitionController?.interactiveTransition else {
                return
            }

            let width = max(
                transitionController?.drawerWidth ?? DrawerTransitionController.defaultDrawerWidth,
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
