import UIKit

@MainActor
extension CompactSidebarViewController {
    func makeBackgroundEffectView() -> UIVisualEffectView {
        if #available(iOS 26.0, *) {
            UIVisualEffectView(effect: UIGlassEffect(style: .regular))
        } else {
            UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
        }
    }

    func configureLayout() {
        materialBackgroundView.contentView.addSubview(collectionView)
        materialBackgroundView.contentView.addSubview(bottomViewContainer)

        bottomViewContainer.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 8,
            leading: 12,
            bottom: 8,
            trailing: 12
        )

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        bottomViewContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(
                equalTo: materialBackgroundView.contentView.topAnchor
            ),
            collectionView.leadingAnchor.constraint(
                equalTo: materialBackgroundView.contentView.leadingAnchor
            ),
            collectionView.trailingAnchor.constraint(
                equalTo: materialBackgroundView.contentView.trailingAnchor
            ),
            collectionView.bottomAnchor.constraint(
                equalTo: materialBackgroundView.contentView.bottomAnchor
            ),
            bottomViewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomViewContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomViewContainer.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor
            ),
        ])

        let emptyHeightConstraint = bottomViewContainer.heightAnchor.constraint(
            equalToConstant: 0
        )
        emptyHeightConstraint.isActive = true
        bottomViewContainerHeightConstraint = emptyHeightConstraint

        if #available(iOS 26.0, *) {
            let interaction = UIScrollEdgeElementContainerInteraction()
            interaction.scrollView = collectionView
            interaction.edge = .bottom
            bottomViewContainer.addInteraction(interaction)
        }
    }

    func updateBottomViewLayout() {
        bottomViewConstraints.forEach { $0.isActive = false }
        bottomViewConstraints.removeAll()
        bottomViewContainer.subviews.forEach { $0.removeFromSuperview() }

        guard let bottomView else {
            bottomViewContainer.isHidden = true
            bottomViewContainerHeightConstraint?.isActive = true
            return
        }

        bottomViewContainer.isHidden = false
        bottomViewContainerHeightConstraint?.isActive = false
        bottomViewContainer.addSubview(bottomView)
        bottomView.translatesAutoresizingMaskIntoConstraints = false

        bottomViewConstraints = [
            bottomView.topAnchor.constraint(
                equalTo: bottomViewContainer.layoutMarginsGuide.topAnchor
            ),
            bottomView.leadingAnchor.constraint(
                equalTo: bottomViewContainer.layoutMarginsGuide.leadingAnchor
            ),
            bottomView.bottomAnchor.constraint(
                equalTo: bottomViewContainer.layoutMarginsGuide.bottomAnchor
            ),
            bottomView.trailingAnchor.constraint(
                equalTo: bottomViewContainer.layoutMarginsGuide.trailingAnchor
            ),
        ]
        NSLayoutConstraint.activate(bottomViewConstraints)
    }

    func updateBottomView() {
        guard isViewLoaded else { return }
        updateBottomViewLayout()
    }

    func updateBottomViewInsets() {
        let bottomInset = bottomViewContainer.isHidden ? 0 : bottomViewContainer.bounds.height
        guard collectionView.contentInset.bottom != bottomInset else { return }

        collectionView.contentInset.bottom = bottomInset
        collectionView.verticalScrollIndicatorInsets.bottom = bottomInset
    }
}
