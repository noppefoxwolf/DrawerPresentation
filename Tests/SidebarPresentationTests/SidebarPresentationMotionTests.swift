import Testing
import UIKit

@testable import SidebarPresentation

@MainActor
struct SidebarPresentationMotionTests {
    @Test("Presentation progress is clamped to the sidebar width")
    func presentationProgress() {
        #expect(
            SidebarGestureMetrics.presentationProgress(
                translation: 160,
                width: 320
            ) == 0.5
        )
        #expect(
            SidebarGestureMetrics.presentationProgress(
                translation: -20,
                width: 320
            ) == 0
        )
        #expect(
            SidebarGestureMetrics.presentationProgress(
                translation: 640,
                width: 320
            ) == 1
        )
    }

    @Test("Dismissal progress uses the reverse horizontal direction")
    func dismissalProgress() {
        #expect(
            SidebarGestureMetrics.dismissalProgress(
                translation: -160,
                width: 320
            ) == 0.5
        )
        #expect(
            SidebarGestureMetrics.dismissalProgress(
                translation: 20,
                width: 320
            ) == 0
        )
    }

    @Test("Sidebar motion calculates its frame from progress")
    func sidebarFrame() {
        let motion = SidebarPresentationMotion(sidebarWidth: 320)
        let bounds = CGRect(x: 0, y: 0, width: 800, height: 600)

        #expect(
            motion.sidebarFrame(progress: 0, in: bounds)
                == CGRect(x: -320, y: 0, width: 320, height: 600)
        )
        #expect(
            motion.sidebarFrame(progress: 1, in: bounds)
                == CGRect(x: 0, y: 0, width: 320, height: 600)
        )
    }
}
