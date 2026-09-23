import SidebarPresentation
import UIKit

@MainActor
public final class AlternativeSidebar: SidebarInteraction {
    private final class DelegateProxy: NSObject, SidebarInteractionDelegate,
        AlternativeSidebarViewControllerDelegate
    {
        weak var owner: AlternativeSidebar?

        func sidebarInteraction(
            _ interaction: SidebarInteraction,
            widthForSidebar sidebarViewController: UIViewController
        ) -> CGFloat {
            SidebarTransitionController.defaultSidebarWidth
        }

        func sidebarInteraction(
            _ interaction: SidebarInteraction,
            presentingViewControllerFor viewController: UIViewController
        ) -> UIViewController? {
            owner?.makeSidebarViewController()
        }

        func viewController(for interaction: SidebarInteraction) -> UIViewController {
            owner?.tabBarController ?? UIViewController()
        }

        func alternativeSidebarViewController(
            _ viewController: AlternativeSidebarViewController,
            didSelect tab: UITab
        ) {
            owner?.didSelect(tab: tab)
        }
    }

    private let delegateProxy: DelegateProxy
    private weak var tabBarController: UITabBarController?
    private weak var presentedSidebarViewController: AlternativeSidebarViewController?
    private weak var presentedSidebarContainerViewController: UIViewController?
    private var traitChangeRegistration: (any UITraitChangeRegistration)?
    private var userIsEnabled = true
    private var isAvailableForInteraction = false

    private struct TabBarPresentationState {
        let isHidden: Bool
        let alpha: CGFloat
        let transform: CGAffineTransform
        let hiddenTransform: CGAffineTransform
    }

    private var tabBarPresentationState: TabBarPresentationState?
    private var tabBarAnimator: UIViewPropertyAnimator?

    private static let tabBarAnimationDuration: TimeInterval = 0.3

    public override var isEnabled: Bool {
        get {
            userIsEnabled && isAvailableForInteraction
        }
        set {
            userIsEnabled = newValue
            super.isEnabled = userIsEnabled && isAvailableForInteraction
        }
    }

    public override func presentationWillChange(isPresented: Bool) {
        guard let tabBarController else { return }
        let tabBar = tabBarController.tabBar

        if isPresented {
            if tabBarPresentationState == nil {
                tabBarPresentationState = TabBarPresentationState(
                    isHidden: tabBar.isHidden,
                    alpha: tabBar.alpha,
                    transform: tabBar.transform,
                    hiddenTransform: tabBar.transform.translatedBy(
                        x: 0,
                        y: tabBar.bounds.height
                    )
                )
            }

            guard let state = tabBarPresentationState, !state.isHidden else { return }
            tabBar.isHidden = false
            animateTabBar(
                tabBar,
                alpha: 0,
                transform: state.hiddenTransform
            )
        } else {
            guard let state = tabBarPresentationState, !state.isHidden else { return }
            tabBar.isHidden = false
            animateTabBar(
                tabBar,
                alpha: state.alpha,
                transform: state.transform
            )
        }
    }

    public override func presentationDidChange(isPresented: Bool) {
        guard let tabBarController, let state = tabBarPresentationState else { return }
        let tabBar = tabBarController.tabBar
        tabBarAnimator?.stopAnimation(true)
        tabBarAnimator = nil

        if isPresented {
            tabBar.alpha = 0
            tabBar.transform = state.hiddenTransform
            tabBar.isHidden = true
        } else {
            tabBar.isHidden = state.isHidden
            tabBar.alpha = state.alpha
            tabBar.transform = state.transform
            tabBarPresentationState = nil
        }
    }

    private func animateTabBar(
        _ tabBar: UITabBar,
        alpha: CGFloat,
        transform: CGAffineTransform
    ) {
        tabBarAnimator?.stopAnimation(true)

        let animator = UIViewPropertyAnimator(
            duration: Self.tabBarAnimationDuration,
            curve: .easeOut
        ) {
            tabBar.alpha = alpha
            tabBar.transform = transform
        }
        tabBarAnimator = animator
        animator.addCompletion { [weak self, weak animator] _ in
            guard let self, self.tabBarAnimator === animator else { return }
            self.tabBarAnimator = nil
        }
        animator.startAnimation()
    }

    public var headerContentConfiguration: UIContentConfiguration? {
        didSet {
            presentedSidebarViewController?.headerConfiguration = headerContentConfiguration
        }
    }

    public var footerContentConfiguration: UIContentConfiguration? {
        didSet {
            presentedSidebarViewController?.footerConfiguration = footerContentConfiguration
        }
    }

    public var bottomBarView: UIView? {
        didSet {
            presentedSidebarViewController?.bottomView = bottomBarView
        }
    }

    public var isHidden: Bool {
        get {
            presentedSidebarContainerViewController?.presentingViewController == nil
        }
        set {
            if newValue {
                dismiss()
            } else {
                present()
            }
        }
    }

    init(tabBarController: UITabBarController) {
        let delegateProxy = DelegateProxy()
        self.delegateProxy = delegateProxy
        self.tabBarController = tabBarController
        super.init(delegate: delegateProxy)
        delegateProxy.owner = self

        updateAvailability()
        traitChangeRegistration = tabBarController.registerForTraitChanges(
            [UITraitHorizontalSizeClass.self],
            target: self,
            action: #selector(updateAvailability)
        )
    }

    isolated deinit {
        if let traitChangeRegistration, let tabBarController {
            tabBarController.unregisterForTraitChanges(traitChangeRegistration)
        }
    }

    @objc
    func updateAvailability() {
        guard let tabBarController else {
            isEnabled = false
            return
        }

        let shouldEnable: Bool
        if #available(iOS 27.0, *) {
            shouldEnable = !tabBarController.sidebar.isAvailable
        } else {
            shouldEnable = tabBarController.traitCollection.horizontalSizeClass == .compact
        }

        isAvailableForInteraction = shouldEnable
        super.isEnabled = userIsEnabled && shouldEnable
        if !shouldEnable, !isHidden {
            dismiss()
        }
    }

    private func makeSidebarViewController() -> UIViewController? {
        guard let tabBarController else { return nil }

        let viewController = AlternativeSidebarViewController(
            tabs: tabBarController.tabs,
            selectedTab: tabBarController.selectedTab,
            headerConfiguration: headerContentConfiguration,
            footerConfiguration: footerContentConfiguration,
            bottomView: bottomBarView
        )
        viewController.delegate = delegateProxy
        let navigationController = UINavigationController(rootViewController: viewController)
        presentedSidebarViewController = viewController
        presentedSidebarContainerViewController = navigationController
        return navigationController
    }

    private func didSelect(tab: UITab) {
        tabBarController?.selectedTab = tab
        dismiss()
    }
}

@MainActor
public extension UITabBarController {
    var alternativeSidebar: AlternativeSidebar {
        if let interaction = view.interactions.first(where: { $0 is AlternativeSidebar })
            as? AlternativeSidebar
        {
            interaction.updateAvailability()
            return interaction
        }

        let interaction = AlternativeSidebar(tabBarController: self)
        view.addInteraction(interaction)
        return interaction
    }
}
