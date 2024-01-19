import UIKit
import Combine

final class DimmingView: UIView {
    var onTap: (() -> Void)? = nil
    var tapGestureCanceller: AnyCancellable? = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        let tapGesture = UITapGestureRecognizer()
        tapGestureCanceller = tapGesture.publisher(for: \.state).filter({ $0 == .ended }).sink(receiveValue: { [unowned self] _ in
            onTap?()
        })
        addGestureRecognizer(tapGesture)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
