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
        collectionView.translatesAutoresizingMaskIntoConstraints = false
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
        ])
    }

    func updateBottomView() {
        guard isViewLoaded else { return }

        guard let bottomView else { return }

        let toolbarItem = UIBarButtonItem(customView: bottomView)
        if #available(iOS 26.0, *) {
            toolbarItem.hidesSharedBackground = true
        }
        toolbarItems = [
            toolbarItem
        ]
        navigationController?.setToolbarHidden(false, animated: false)
    }
}
