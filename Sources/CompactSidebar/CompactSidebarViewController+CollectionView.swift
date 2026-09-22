import UIKit

@MainActor
extension CompactSidebarViewController {
    func makeCellRegistration() -> UICollectionView.CellRegistration<UICollectionViewListCell, Int>
    {
        UICollectionView.CellRegistration<UICollectionViewListCell, Int> {
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
    }

    func makeHeaderRegistration()
        -> UICollectionView.SupplementaryRegistration<UICollectionViewListCell>
    {
        UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(
            elementKind: UICollectionView.elementKindSectionHeader
        ) { [weak self] supplementaryView, _, _ in
            supplementaryView.contentConfiguration = self?.headerConfiguration
        }
    }

    func makeFooterRegistration()
        -> UICollectionView.SupplementaryRegistration<UICollectionViewListCell>
    {
        UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(
            elementKind: UICollectionView.elementKindSectionFooter
        ) { [weak self] supplementaryView, _, _ in
            supplementaryView.contentConfiguration = self?.footerConfiguration
        }
    }

    func configureCollectionView() {
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.allowsMultipleSelection = false
        collectionView.contentInsetAdjustmentBehavior = .automatic
        if #available(iOS 26.0, *) {
            collectionView.bottomEdgeEffect.style = .hard
        }

        _ = cellRegistration
        _ = headerRegistration
        _ = footerRegistration

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

    func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, Int>()
        snapshot.appendSections([0])
        snapshot.appendItems(Array(tabs.indices), toSection: 0)
        dataSource.apply(snapshot, animatingDifferences: false)
        updateSelection(animated: false)
    }

    func updateSelection(animated: Bool) {
        guard isViewLoaded,
            let selectedTab,
            let tabIndex = tabs.firstIndex(where: { $0 === selectedTab })
        else {
            return
        }

        collectionView.selectItem(
            at: IndexPath(item: tabIndex, section: 0),
            animated: animated,
            scrollPosition: []
        )
    }
}

@MainActor
extension CompactSidebarViewController: UICollectionViewDelegate {
    public func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        guard tabs.indices.contains(indexPath.item) else { return }

        let selectedTab = tabs[indexPath.item]
        self.selectedTab = selectedTab
        delegate?.compactSidebarViewController(self, didSelect: selectedTab)
    }
}
