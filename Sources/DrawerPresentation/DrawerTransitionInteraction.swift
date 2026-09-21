import UIKit
import InteractiveContainerPanGestureRecognizer

@MainActor
open class DrawerInteraction: NSObject, UIInteraction {
    public weak var delegate: (any DrawerInteractionDelegate)? = nil
    
    let presentPanGesture = InteractiveContainerPanGestureRecognizer()
    
    var transitionController: DrawerTransitionController? = nil
    
    public init(delegate: any DrawerInteractionDelegate) {
        self.delegate = delegate
        super.init()
    }
    
    public weak var view: UIView? = nil
    
    public func willMove(to view: UIView?) {
        self.view = view
    }
    
    public func didMove(to view: UIView?) {
        #if os(iOS)
        presentPanGesture.addTarget(self, action: #selector(onPan))
        presentPanGesture.maximumNumberOfTouches = 1
        view?.addGestureRecognizer(presentPanGesture)
        #endif
    }
    
    public func present() {
        present(isInteractiveTransitoionEnabled: false)
    }
    
    private func present(isInteractiveTransitoionEnabled: Bool) {
        guard let parent = delegate?.viewController(for: self) else { return }
        guard let vc = delegate?.drawerInteraction(self, presentingViewControllerFor: parent) else { return }
        let drawerWidth = delegate?.drawerInteraction(self, widthForDrawer: vc) ?? 300
        transitionController = DrawerTransitionController(drawerWidth: drawerWidth)
        if isInteractiveTransitoionEnabled {
            transitionController?.interactiveTransition = UIPercentDrivenInteractiveTransition()
        }
        #if os(iOS)
        vc.modalPresentationStyle = .custom
        vc.transitioningDelegate = transitionController
        #endif
        if #available(iOS 17.0, *) {
            vc.traitOverrides.userInterfaceLevel = .elevated
        }
        parent.present(vc, animated: true)
    }
    
    @objc
    private func onPan(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            break
        case .changed:
            if transitionController?.interactiveTransition == nil {
                present(isInteractiveTransitoionEnabled: true)
                transitionController?.interactiveTransition?.completionCurve = .easeOut
                transitionController?.interactiveTransition?.update(0)
            } else {
                let x = gesture.translation(in: gesture.view).x
                let presentedViewController = delegate?.viewController(for: self)
                let width = presentedViewController.map { delegate?.drawerInteraction(self, widthForDrawer: $0) }?.flatMap({ $0 }) ?? 300.0
                let percentComplete = max(x / width, 0)
                transitionController?.interactiveTransition?.update(percentComplete)
            }
        case .ended:
            let velocity = gesture.velocity(in: gesture.view).x
            let presentedViewController = delegate?.viewController(for: self)
            let width = presentedViewController.map { delegate?.drawerInteraction(self, widthForDrawer: $0) }?.flatMap({ $0 }) ?? 300.0
            transitionController?.setInteractiveSpring(progressVelocity: velocity / width)
            if velocity > 0 {
                transitionController?.interactiveTransition?.finish()
            } else {
                transitionController?.interactiveTransition?.cancel()
            }
            transitionController?.interactiveTransition = nil
        case .cancelled:
            let velocity = gesture.velocity(in: gesture.view).x
            let presentedViewController = delegate?.viewController(for: self)
            let width = presentedViewController.map { delegate?.drawerInteraction(self, widthForDrawer: $0) }?.flatMap({ $0 }) ?? 300.0
            transitionController?.setInteractiveSpring(progressVelocity: velocity / width)
            transitionController?.interactiveTransition?.cancel()
            transitionController?.interactiveTransition = nil
        default:
            break
        }
    }
}
