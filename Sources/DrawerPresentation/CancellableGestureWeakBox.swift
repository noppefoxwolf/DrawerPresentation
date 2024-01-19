import UIKit

final class CancellableGestureWeakBox {
    weak var gestureRecognizer: UIGestureRecognizer? = nil
    
    init(_ gestureRecognizer: UIGestureRecognizer) {
        self.gestureRecognizer = gestureRecognizer
    }
}
