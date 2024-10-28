import UIKit

final class TapActionInteraction: NSObject, UIInteraction {
    weak var view: UIView?
    let action: @MainActor @Sendable () -> Void
    
    init(action: @MainActor @escaping @Sendable () -> Void) {
        self.action = action
    }
    
    func willMove(to view: UIView?) {
        self.view = view
    }
    
    func didMove(to view: UIView?) {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTap))
        view?.addGestureRecognizer(tapGesture)
    }
    
    @objc
    func onTap(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended else { return }
        action()
    }
}
