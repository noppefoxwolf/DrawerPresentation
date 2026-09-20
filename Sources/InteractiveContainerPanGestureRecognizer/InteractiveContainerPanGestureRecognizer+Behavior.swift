//
//  InteractiveContainerPanGestureRecognizer+Behavior.swift
//  GestureSample
//

import UIKit

@MainActor
extension InteractiveContainerPanGestureRecognizer {

    enum BehaviorEvent {
        case shouldReceive(touch: UITouch, scrollView: UIScrollView?)
        case shouldBegin(location: CGPoint, velocity: CGPoint, scrollView: UIScrollView?)
        case shouldRecognizeSimultaneously(other: UIGestureRecognizer)
        case shouldRequireFailureOf(other: UIGestureRecognizer)
        case shouldBeRequiredToFailBy(other: UIGestureRecognizer)
    }

    enum BehaviorDecision {
        case allow
        case deny
        case ignore
    }

    @MainActor
    struct Behavior {
        typealias Handler = (InteractiveContainerPanGestureRecognizer, BehaviorEvent) -> BehaviorDecision

        private let handler: Handler

        private init(handler: @escaping Handler) {
            self.handler = handler
        }

        /// Creates a behavior that can participate in every gesture decision.
        static func custom(_ handler: @escaping Handler) -> Behavior {
            Behavior(handler: handler)
        }

        /// Gives the custom pan priority when the touched scroll view is at its edge.
        static let scrollView = Behavior.custom { recognizer, event in
            switch event {
            case .shouldReceive(let touch, _):
                recognizer.requireScrollViewsToWait(for: touch.view)
                return .ignore

            case .shouldBegin(_, _, let scrollView):
                guard let scrollView else {
                    return .ignore
                }
                return recognizer.isAtBoundary(of: scrollView) ? .ignore : .deny

            default:
                return .ignore
            }
        }

        /// Gives the system navigation pop transition priority over the custom pan.
        static let popInteraction = Behavior.custom { recognizer, event in
            switch event {
            case .shouldRequireFailureOf(let other):
                return recognizer.isNavigationTransitionGesture(other)
                    ? .allow
                    : .ignore

            default:
                return .ignore
            }
        }

        fileprivate func evaluate(
            with recognizer: InteractiveContainerPanGestureRecognizer,
            event: BehaviorEvent
        ) -> BehaviorDecision {
            handler(recognizer, event)
        }
    }

    package func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive touch: UITouch
    ) -> Bool {
        guard gestureRecognizer === self, let rootView = view else {
            return true
        }

        trackedScrollView = nearestScrollView(from: touch.view)
        let event = BehaviorEvent.shouldReceive(
            touch: touch,
            scrollView: trackedScrollView
        )
        let shouldReceive = !decisions(for: event).contains(where: isDenied)
        let location = touch.location(in: rootView)
        log(
            "shouldReceive touch location=\(location) "
                + "view=\(viewDescription(touch.view)) "
                + "scrollView=\(viewDescription(trackedScrollView)) "
                + "-> \(shouldReceive)"
        )
        logGestureContext(at: location)
        return shouldReceive
    }

    package func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer === self, let rootView = view else {
            return true
        }

        let location = location(in: rootView)
        let velocity = velocity(in: rootView)
        let hasMatchingDirection = matchesDirection(velocity)
        let isAtScrollViewBoundary = trackedScrollView.map {
            isAtBoundary(of: $0)
        } ?? true
        let event = BehaviorEvent.shouldBegin(
            location: location,
            velocity: velocity,
            scrollView: trackedScrollView
        )
        let shouldBegin = hasMatchingDirection
            && !decisions(for: event).contains(where: isDenied)
        log(
            "shouldBegin "
                + "location=\(location) "
                + "velocity=\(velocity) "
                + "direction=\(direction) "
                + "atBoundary=\(isAtScrollViewBoundary) -> \(shouldBegin)"
        )
        return shouldBegin
    }

    package func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        guard gestureRecognizer === self else {
            return false
        }

        let event = BehaviorEvent.shouldRecognizeSimultaneously(
            other: otherGestureRecognizer
        )
        let decisions = decisions(for: event)
        let shouldRecognizeSimultaneously = !decisions.contains(where: isDenied)
            && decisions.contains(where: isAllowed)
        log(
            "simultaneous "
                + "other=\(recognizerDescription(otherGestureRecognizer)) "
                + "-> \(shouldRecognizeSimultaneously)"
        )
        return shouldRecognizeSimultaneously
    }

    package func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        guard gestureRecognizer === self else {
            return false
        }

        let event = BehaviorEvent.shouldRequireFailureOf(
            other: otherGestureRecognizer
        )
        let decisions = decisions(for: event)
        let shouldRequireFailure = !decisions.contains(where: isDenied)
            && decisions.contains(where: isAllowed)
        log(
            "shouldRequireFailureOf "
                + "other=\(recognizerDescription(otherGestureRecognizer)) "
                + "-> \(shouldRequireFailure)"
        )
        return shouldRequireFailure
    }

    package func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        guard gestureRecognizer === self else {
            return false
        }

        let event = BehaviorEvent.shouldBeRequiredToFailBy(
            other: otherGestureRecognizer
        )
        let decisions = decisions(for: event)
        let shouldBeRequiredToFailBy = !decisions.contains(where: isDenied)
            && decisions.contains(where: isAllowed)
        log(
            "shouldBeRequiredToFailBy "
                + "other=\(recognizerDescription(otherGestureRecognizer)) "
                + "-> \(shouldBeRequiredToFailBy)"
        )
        return shouldBeRequiredToFailBy
    }

    private func decisions(for event: BehaviorEvent) -> [BehaviorDecision] {
        behavior.map { $0.evaluate(with: self, event: event) }
    }

    private func isDenied(_ decision: BehaviorDecision) -> Bool {
        if case .deny = decision {
            return true
        }
        return false
    }

    private func isAllowed(_ decision: BehaviorDecision) -> Bool {
        if case .allow = decision {
            return true
        }
        return false
    }

    fileprivate func isNavigationTransitionGesture(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer is UIPanGestureRecognizer
                || gestureRecognizer is UIScreenEdgePanGestureRecognizer,
              let gestureView = gestureRecognizer.view,
              let navigationController = navigationController(containing: gestureView),
              navigationController.view === gestureView,
              navigationController.viewControllers.count > 1 else {
            return false
        }

        return true
    }

    private func matchesDirection(_ velocity: CGPoint) -> Bool {
        switch direction {
        case .left:
            return velocity.x < 0 && abs(velocity.x) >= abs(velocity.y)
        case .right:
            return velocity.x > 0 && abs(velocity.x) >= abs(velocity.y)
        case .up:
            return velocity.y < 0 && abs(velocity.y) >= abs(velocity.x)
        case .down:
            return velocity.y > 0 && abs(velocity.y) >= abs(velocity.x)
        }
    }

    private func nearestScrollView(from view: UIView?) -> UIScrollView? {
        var currentView = view

        while let current = currentView {
            if let scrollView = current as? UIScrollView {
                return scrollView
            }
            currentView = current.superview
        }

        return nil
    }

    fileprivate func requireScrollViewsToWait(for view: UIView?) {
        var currentView = view

        while let current = currentView {
            if let scrollView = current as? UIScrollView {
                scrollView.panGestureRecognizer.require(toFail: self)
            }
            currentView = current.superview
        }
    }

    fileprivate func isAtBoundary(of scrollView: UIScrollView) -> Bool {
        let inset = scrollView.adjustedContentInset
        let tolerance: CGFloat = 1

        switch direction {
        case .left:
            let minimumOffset = -inset.left
            let maximumOffset = max(
                minimumOffset,
                scrollView.contentSize.width
                    - scrollView.bounds.width
                    + inset.right
            )
            return scrollView.contentOffset.x >= maximumOffset - tolerance

        case .right:
            let minimumOffset = -inset.left
            return scrollView.contentOffset.x <= minimumOffset + tolerance

        case .up:
            let minimumOffset = -inset.top
            let maximumOffset = max(
                minimumOffset,
                scrollView.contentSize.height
                    - scrollView.bounds.height
                    + inset.bottom
            )
            return scrollView.contentOffset.y >= maximumOffset - tolerance

        case .down:
            let minimumOffset = -inset.top
            return scrollView.contentOffset.y <= minimumOffset + tolerance
        }
    }

    private func navigationController(containing view: UIView) -> UINavigationController? {
        var responder: UIResponder? = view

        while let currentResponder = responder {
            if let navigationController = currentResponder as? UINavigationController {
                return navigationController
            }

            responder = currentResponder.next
        }

        return nil
    }

    private func logGestureContext(at location: CGPoint) {
        guard let rootView = view else {
            return
        }

        guard let hitView = rootView.hitTest(location, with: nil) else {
            log("context hitView=nil")
            return
        }

        log("context hitView=\(viewDescription(hitView))")

        var currentView: UIView? = hitView
        while let current = currentView {
            let recognizers = current.gestureRecognizers ?? []
            log(
                "context view=\(viewDescription(current)) "
                    + "recognizers=[\(recognizers.map(recognizerDescription).joined(separator: ", "))]"
            )
            currentView = current.superview
        }

        var responder: UIResponder? = hitView
        while let currentResponder = responder {
            if let navigationController = currentResponder as? UINavigationController {
                log(
                    "context navigation=\(type(of: navigationController)) "
                        + "stackCount=\(navigationController.viewControllers.count) "
                        + "interactivePop=\(recognizerDescription(navigationController.interactivePopGestureRecognizer))"
                )
            }
            responder = currentResponder.next
        }
    }

    private func log(_ message: String) {
        guard isDebugLoggingEnabled else {
            return
        }

        print("[GestureDebug] \(message)")
    }

    private func viewDescription(_ view: UIView?) -> String {
        guard let view else {
            return "nil"
        }

        return "\(type(of: view))#\(ObjectIdentifier(view))"
    }

    private func recognizerDescription(_ recognizer: UIGestureRecognizer?) -> String {
        guard let recognizer else {
            return "nil"
        }

        return "\(type(of: recognizer))#\(ObjectIdentifier(recognizer))"
            + " state=\(stateName(recognizer.state))"
            + " enabled=\(recognizer.isEnabled)"
            + " view=\(viewDescription(recognizer.view))"
    }

    private func stateName(_ state: UIGestureRecognizer.State) -> String {
        switch state {
        case .possible:
            return "possible"
        case .began:
            return "began"
        case .changed:
            return "changed"
        case .ended:
            return "ended"
        case .cancelled:
            return "cancelled"
        case .failed:
            return "failed"
        @unknown default:
            return "unknown(\(state.rawValue))"
        }
    }
}
