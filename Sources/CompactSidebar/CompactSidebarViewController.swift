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
    private let tabs: [UITab]

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

    private let materialBackgroundView: UIVisualEffectView
    private let bottomViewContainer = UIView()
    private let collectionView: UICollectionView
    private var cellRegistration: UICollectionView.CellRegistration<UICollectionViewListCell, Int>!
    private var headerRegistration: UICollectionView.SupplementaryRegistration<UICollectionViewListCell>!
    private var footerRegistration: UICollectionView.SupplementaryRegistration<UICollectionViewListCell>!
    private var dataSource: UICollectionViewDiffableDataSource<Int, Int>!

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
        self.materialBackgroundView = UIVisualEffectView(
            effect: Self.makeBackgroundEffect()
        )

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

    private static func makeBackgroundEffect() -> UIVisualEffect {
        if #available(iOS 26.0, *) {
            return UIGlassEffect(style: .regular)
        } else {
            return UIBlurEffect(style: .systemMaterial)
        }
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

    public override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .clear
        configureMaterialBackground()
        configureCollectionView()
        configureLayout()
        applySnapshot()
        updateBottomView()
    }

    private func configureMaterialBackground() {
        view.addSubview(materialBackgroundView)
        materialBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            materialBackgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            materialBackgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.bottomAnchor.constraint(equalTo: materialBackgroundView.bottomAnchor),
            view.trailingAnchor.constraint(equalTo: materialBackgroundView.trailingAnchor),
        ])
    }

    private func configureCollectionView() {
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.allowsMultipleSelection = false
        collectionView.contentInsetAdjustmentBehavior = .automatic

        cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Int> {
            [weak self] cell, _, tabIndex in
            guard let self, self.tabs.indices.contains(tabIndex) else { return }

            let tab = self.tabs[tabIndex]
            let title = tab.title
            let image = tab.image

            cell.accessories = []
            cell.accessibilityIdentifier = "compactSidebar.tab.\(tabIndex)"
            cell.configurationUpdateHandler = { cell, state in
                let foregroundColor: UIColor = state.isSelected ? .white : .label
                let imageTintColor: UIColor = state.isSelected ? .white : .tintColor

                var content = UIListContentConfiguration.cell()
                content.text = title
                content.secondaryText = tab.subtitle
                content.image = image
                content.textProperties.color = foregroundColor
                content.secondaryTextProperties.color = foregroundColor
                content.imageProperties.tintColor = imageTintColor

                var background = UIBackgroundConfiguration.listCell()
                background.backgroundColor = state.isSelected ? .tintColor : .clear
                cell.backgroundConfiguration = background
                cell.contentConfiguration = content
            }
            cell.setNeedsUpdateConfiguration()
        }

        headerRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(
            elementKind: UICollectionView.elementKindSectionHeader
        ) { [weak self] supplementaryView, _, _ in
            supplementaryView.contentConfiguration = self?.headerConfiguration
        }
        footerRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(
            elementKind: UICollectionView.elementKindSectionFooter
        ) { [weak self] supplementaryView, _, _ in
            supplementaryView.contentConfiguration = self?.footerConfiguration
        }

        dataSource = UICollectionViewDiffableDataSource<Int, Int>(
            collectionView: collectionView
        ) { [weak self] collectionView, indexPath, tabIndex in
            guard let self else { return nil }
            return collectionView.dequeueConfiguredReusableCell(
                using: self.cellRegistration,
                for: indexPath,
                item: tabIndex
            )
        }

        dataSource.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            guard let self else { return nil }

            switch kind {
            case UICollectionView.elementKindSectionHeader:
                return collectionView.dequeueConfiguredReusableSupplementary(
                    using: self.headerRegistration,
                    for: indexPath
                )
            case UICollectionView.elementKindSectionFooter:
                return collectionView.dequeueConfiguredReusableSupplementary(
                    using: self.footerRegistration,
                    for: indexPath
                )
            default:
                return nil
            }
        }
    }

    private func configureLayout() {
        bottomViewContainer.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 8,
            leading: 12,
            bottom: 8,
            trailing: 12
        )

        view.addSubview(collectionView)
        view.addSubview(bottomViewContainer)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        bottomViewContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomViewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomViewContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: bottomViewContainer.bottomAnchor),
        ])
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let bottomInset = bottomViewContainer.isHidden ? 0 : bottomViewContainer.bounds.height
        guard collectionView.contentInset.bottom != bottomInset else { return }

        collectionView.contentInset.bottom = bottomInset
        collectionView.verticalScrollIndicatorInsets.bottom = bottomInset
    }

    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, Int>()
        snapshot.appendSections([0])
        snapshot.appendItems(Array(tabs.indices), toSection: 0)
        dataSource.apply(snapshot, animatingDifferences: false)
        updateSelection(animated: false)
    }

    private func updateSelection(animated: Bool) {
        guard isViewLoaded,
              let selectedTab,
              let tabIndex = tabs.firstIndex(where: { $0 === selectedTab }) else {
            return
        }

        collectionView.selectItem(
            at: IndexPath(item: tabIndex, section: 0),
            animated: animated,
            scrollPosition: []
        )
    }

    private func updateBottomView() {
        guard isViewLoaded else { return }

        bottomViewContainer.subviews.forEach { $0.removeFromSuperview() }
        bottomViewContainer.isHidden = bottomView == nil

        guard let bottomView else { return }

        bottomViewContainer.addSubview(bottomView)
        bottomView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bottomView.topAnchor.constraint(equalTo: bottomViewContainer.layoutMarginsGuide.topAnchor),
            bottomView.leadingAnchor.constraint(equalTo: bottomViewContainer.layoutMarginsGuide.leadingAnchor),
            bottomViewContainer.layoutMarginsGuide.bottomAnchor.constraint(equalTo: bottomView.bottomAnchor),
            bottomViewContainer.layoutMarginsGuide.trailingAnchor.constraint(equalTo: bottomView.trailingAnchor),
        ])
    }
}

@MainActor
extension CompactSidebarViewController: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard tabs.indices.contains(indexPath.item) else { return }

        let selectedTab = tabs[indexPath.item]
        self.selectedTab = selectedTab
        delegate?.compactSidebarViewController(self, didSelect: selectedTab)
    }
}
