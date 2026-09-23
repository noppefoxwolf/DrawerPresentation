import Foundation

public enum SidebarPresentation: Sendable, Equatable {
    case modal(movesPresentingView: Bool)
    case embedded
}
