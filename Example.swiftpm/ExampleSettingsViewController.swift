import UIKit

@MainActor
final class ExampleSettings {
    static let shared = ExampleSettings()

    var isSidebarEnabled = true

    private init() {}
}

@MainActor
final class ExampleSettingsViewController: UIViewController {
    private let settings = ExampleSettings.shared
    private let sidebarEnabledSwitch = UISwitch()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        view.backgroundColor = .systemGroupedBackground

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "sidebar.left"),
            primaryAction: UIAction { [weak self] _ in
                (self?.tabBarController as? ExampleTabBarController)?.presentSidebar()
            }
        )

        sidebarEnabledSwitch.isOn = settings.isSidebarEnabled
        sidebarEnabledSwitch.accessibilityLabel = "Enable Sidebar"
        sidebarEnabledSwitch.addTarget(
            self,
            action: #selector(sidebarEnabledSwitchChanged),
            for: .valueChanged
        )

        let sidebarEnabledRow = makeSwitchRow(
            title: "Enable Sidebar",
            detail: "Allow swiping from the edge to open the sidebar.",
            control: sidebarEnabledSwitch
        )

        let rows = UIStackView(arrangedSubviews: [sidebarEnabledRow])
        rows.axis = .vertical
        rows.spacing = 12

        view.addSubview(rows)
        rows.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            rows.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            rows.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            view.trailingAnchor.constraint(equalTo: rows.trailingAnchor, constant: 16),
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
    private func sidebarEnabledSwitchChanged(_ sender: UISwitch) {
        settings.isSidebarEnabled = sender.isOn
        (tabBarController as? ExampleTabBarController)?.updateSidebarSettings()
    }

}
