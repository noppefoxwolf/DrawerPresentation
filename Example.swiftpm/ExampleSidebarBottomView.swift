import UIKit

@MainActor
final class ExampleSidebarBottomView: UIView {
    private let profileControl = UIControl()
    private let avatarView = UIImageView(image: UIImage(systemName: "person.crop.circle.fill"))
    private let nameLabel = UILabel()
    private let detailLabel = UILabel()
    private let chevronView = UIImageView(image: UIImage(systemName: "chevron.right"))

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    private func configure() {
        directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 8,
            leading: 12,
            bottom: 8,
            trailing: 12
        )

        avatarView.tintColor = .systemBlue
        avatarView.contentMode = .scaleAspectFit

        nameLabel.text = "Noppe Foxwolf"
        nameLabel.font = .preferredFont(forTextStyle: .body)
        nameLabel.textColor = .label

        detailLabel.text = "Account"
        detailLabel.font = .preferredFont(forTextStyle: .caption1)
        detailLabel.textColor = .secondaryLabel

        let labelsStackView = UIStackView(arrangedSubviews: [nameLabel, detailLabel])
        labelsStackView.axis = .vertical
        labelsStackView.spacing = 2

        let spacerView = UIView()
        spacerView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacerView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        chevronView.tintColor = .tertiaryLabel
        chevronView.contentMode = .scaleAspectFit

        let contentStackView = UIStackView(arrangedSubviews: [
            avatarView,
            labelsStackView,
            spacerView,
            chevronView,
        ])
        contentStackView.axis = .horizontal
        contentStackView.alignment = .center
        contentStackView.spacing = 10

        profileControl.accessibilityLabel = "Noppe Foxwolf, Account"
        profileControl.accessibilityTraits = .button

        profileControl.addSubview(contentStackView)
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: profileControl.topAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: profileControl.leadingAnchor),
            profileControl.bottomAnchor.constraint(equalTo: contentStackView.bottomAnchor),
            profileControl.trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor),
        ])

        avatarView.translatesAutoresizingMaskIntoConstraints = false
        chevronView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            avatarView.widthAnchor.constraint(equalToConstant: 32),
            avatarView.heightAnchor.constraint(equalToConstant: 32),
            chevronView.widthAnchor.constraint(equalToConstant: 12),
            chevronView.heightAnchor.constraint(equalToConstant: 18),
        ])

        addSubview(profileControl)
        profileControl.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            profileControl.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            profileControl.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            layoutMarginsGuide.bottomAnchor.constraint(equalTo: profileControl.bottomAnchor),
            profileControl.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            profileControl.heightAnchor.constraint(equalToConstant: 52),
        ])
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 68)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
