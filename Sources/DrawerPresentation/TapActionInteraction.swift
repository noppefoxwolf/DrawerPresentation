import UIKit

final class TapActionInteraction: NSObject, UIInteraction {
    weak var view: UIView?
    let action: @MainActor @Sendable () -> Void
    private lazy var tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTap))

    var isEnabled: Bool = true {
        didSet {
            tapGesture.isEnabled = isEnabled
        }
    }
    
    init(action: @MainActor @escaping @Sendable () -> Void) {
        self.action = action
    }
    
    func willMove(to view: UIView?) {
        self.view = view
    }
    
    func didMove(to view: UIView?) {
        tapGesture.isEnabled = isEnabled
        view?.addGestureRecognizer(tapGesture)
    }
    
    @objc
    func onTap(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended else { return }
        action()
    }
}
