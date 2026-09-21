import UIKit

@MainActor
public protocol CompactSidebarViewControllerDelegate: AnyObject {
    func compactSidebarViewController(
        _ viewController: CompactSidebarViewController,
        didSelect tab: UITab
    )
}

@MainActor
public final class CompactSidebarViewController: UIViewController {
    internal let tabs: [UITab]

    public weak var delegate: (any CompactSidebarViewControllerDelegate)?

    public var selectedTab: UITab? {
        didSet {
            updateSelection(animated: false)
        }
    }

    public var headerConfiguration: UIContentConfiguration? {
        didSet {
            if isViewLoaded {
                collectionView.reloadData()
            }
        }
    }

    public var footerConfiguration: UIContentConfiguration? {
        didSet {
            if isViewLoaded {
                collectionView.reloadData()
            }
        }
    }

    public var bottomView: UIView? {
        didSet {
            updateBottomView()
        }
    }

    internal var materialBackgroundView: UIVisualEffectView {
        view as! UIVisualEffectView
    }

    internal let collectionView: UICollectionView

    internal lazy var cellRegistration = makeCellRegistration()
    internal lazy var headerRegistration = makeHeaderRegistration()
    internal lazy var footerRegistration = makeFooterRegistration()
    internal var dataSource: UICollectionViewDiffableDataSource<Int, Int>!

    public init(
        tabs: [UITab],
        selectedTab: UITab? = nil,
        headerConfiguration: UIContentConfiguration? = nil,
        footerConfiguration: UIContentConfiguration? = nil,
        bottomView: UIView? = nil
    ) {
        self.tabs = tabs.filter { !$0.isHidden }
        self.selectedTab = selectedTab
        self.headerConfiguration = headerConfiguration
        self.footerConfiguration = footerConfiguration
        self.bottomView = bottomView

        var layoutConfiguration = UICollectionLayoutListConfiguration(appearance: .sidebar)
        layoutConfiguration.showsSeparators = false
        layoutConfiguration.backgroundColor = .clear
        layoutConfiguration.headerMode = .supplementary
        layoutConfiguration.footerMode = .supplementary

        collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: UICollectionViewCompositionalLayout.list(
                using: layoutConfiguration
            )
        )

        super.init(nibName: nil, bundle: nil)
    }

    @available(iOS 27.1, *)
    public override var preferredVerticalBarBehavior: UIVerticalBarBehavior {
        .disabled
    }

    /// Creates a sidebar using the tab and sidebar configuration from a tab bar controller.
    public convenience init(tabBarController: UITabBarController) {
        self.init(
            tabs: tabBarController.tabs,
            selectedTab: tabBarController.selectedTab,
            headerConfiguration: tabBarController.sidebar.headerContentConfiguration,
            footerConfiguration: tabBarController.sidebar.footerContentConfiguration,
            bottomView: tabBarController.sidebar.bottomBarView
        )
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    isolated deinit {
        bottomView?.removeFromSuperview()
    }

    public override func loadView() {
        super.loadView()
        view = makeBackgroundEffectView()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        configureCollectionView()
        configureLayout()
        setContentScrollView(collectionView, for: .bottom)
        applySnapshot()
        updateBottomView()
    }
}
