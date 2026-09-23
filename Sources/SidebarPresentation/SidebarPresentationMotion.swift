import UIKit

@MainActor
struct SidebarPresentationMotion {
    static let animationDuration: TimeInterval = 0.3
    static let animationCurve: UIView.AnimationCurve = .easeOut
    static let completionThreshold: CGFloat = 0.5

    let sidebarWidth: CGFloat

    func sidebarWidth(in bounds: CGRect) -> CGFloat {
        min(max(sidebarWidth, 0), bounds.width)
    }

    func sidebarFrame(progress: CGFloat, in bounds: CGRect) -> CGRect {
        let progress = min(max(progress, 0), 1)
        let width = sidebarWidth(in: bounds)
        return CGRect(
            x: bounds.minX - width + width * progress,
            y: bounds.minY,
            width: width,
            height: bounds.height
        )
    }

    func apply(
        progress: CGFloat,
        sidebarView: UIView,
        dimmingView: UIView,
        in bounds: CGRect
    ) {
        sidebarView.frame = sidebarFrame(progress: progress, in: bounds)
        dimmingView.frame = bounds
        dimmingView.alpha = min(max(progress, 0), 1)
    }
}

@MainActor
enum SidebarGestureMetrics {
    static func presentationProgress(translation: CGFloat, width: CGFloat) -> CGFloat {
        min(max(translation / max(width, 1), 0), 1)
    }

    static func dismissalProgress(translation: CGFloat, width: CGFloat) -> CGFloat {
        min(max(-translation / max(width, 1), 0), 1)
    }

    static func shouldFinishPresentation(velocity: CGFloat, progress: CGFloat) -> Bool {
        velocity > 0 || progress >= SidebarPresentationMotion.completionThreshold
    }

    static func shouldFinishDismissal(velocity: CGFloat, progress: CGFloat) -> Bool {
        velocity < 0 || progress >= SidebarPresentationMotion.completionThreshold
    }
}
