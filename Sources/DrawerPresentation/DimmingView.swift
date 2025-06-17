import UIKit
import Combine

final class DimmingView: UIVisualEffectView {
    var intensity: CGFloat = 0 {
        didSet {
            print(intensity)
            animator.fractionComplete = intensity * 0.3
        }
    }
    
    let animator = UIViewPropertyAnimator(duration: 1, curve: .linear)
    
    init() {
        super.init(effect: nil)
        backgroundColor = .clear
        
        animator.addAnimations {
            self.effect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        }
        
        animator.startAnimation()
        animator.pauseAnimation()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

//final class DimmingView: UIView {
//    var intensity: CGFloat = 0 {
//        didSet {
//            print(intensity)
//            alpha = intensity
//        }
//    }
//    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        backgroundColor = UIColor.black.withAlphaComponent(0.5)
//    }
//    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//}
