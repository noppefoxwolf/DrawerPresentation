import UIKit

final class CancellableGestureWeakBox: Equatable, Hashable {
    weak var gestureRecognizer: UIGestureRecognizer? = nil
    
    init(_ gestureRecognizer: UIGestureRecognizer) {
        self.gestureRecognizer = gestureRecognizer
    }
    
    static func == (lhs: CancellableGestureWeakBox, rhs: CancellableGestureWeakBox) -> Bool {
        lhs.gestureRecognizer == rhs.gestureRecognizer
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(gestureRecognizer)
        hasher.finalize()
    }
}
