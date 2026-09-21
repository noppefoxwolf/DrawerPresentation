import UIKit

@MainActor
final class ExampleSettings {
    static let shared = ExampleSettings()

    var movesPresentingView = true

    private init() {}
}

@MainActor
final class ExampleSettingsViewController: UIViewController {
    private let settings = ExampleSettings.shared
    private let movesPresentingViewSwitch = UISwitch()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        view.backgroundColor = .systemGroupedBackground

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "line.3.horizontal"),
            primaryAction: UIAction { [weak self] _ in
                (self?.tabBarController as? ExampleTabBarController)?.presentDrawer()
            }
        )

        movesPresentingViewSwitch.isOn = settings.movesPresentingView
        movesPresentingViewSwitch.accessibilityLabel = "Move presenting view"
        movesPresentingViewSwitch.addTarget(
            self,
            action: #selector(movesPresentingViewSwitchChanged),
            for: .valueChanged
        )

        let row = makeSwitchRow(
            title: "Move presenting view",
            detail: "Move the current screen along with the drawer.",
            control: movesPresentingViewSwitch
        )

        view.addSubview(row)
        row.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            row.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            view.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: 16),
        ])
    }

    private func makeSwitchRow(
        title: String,
        detail: String,
        control: UISwitch
    ) -> UIView {
        let titleLabel = UILabel()
        titleLabel.font = .preferredFont(forTextStyle: .body)
        titleLabel.text = title

        let detailLabel = UILabel()
        detailLabel.font = .preferredFont(forTextStyle: .footnote)
        detailLabel.textColor = .secondaryLabel
        detailLabel.numberOfLines = 0
        detailLabel.text = detail

        let labels = UIStackView(arrangedSubviews: [titleLabel, detailLabel])
        labels.axis = .vertical
        labels.spacing = 4

        let row = UIStackView(arrangedSubviews: [labels, control])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 16
        row.isLayoutMarginsRelativeArrangement = true
        row.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 16,
            leading: 16,
            bottom: 16,
            trailing: 16
        )
        row.backgroundColor = .secondarySystemGroupedBackground
        return row
    }

    @objc
    private func movesPresentingViewSwitchChanged(_ sender: UISwitch) {
        settings.movesPresentingView = sender.isOn
        (tabBarController as? ExampleTabBarController)?.updateDrawerSettings()
    }
}
