import UIKit

@MainActor
final class ExampleSplitViewController: UISplitViewController {
    private let primaryNavigationController = UINavigationController(
        rootViewController: SplitPrimaryViewController()
    )
    private let supplementaryNavigationController = UINavigationController(
        rootViewController: SplitSupplementaryViewController()
    )
    private let secondaryNavigationController = UINavigationController(
        rootViewController: SplitSecondaryViewController()
    )

    init() {
        super.init(style: .tripleColumn)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        preferredSplitBehavior = .tile
        preferredDisplayMode = .oneBesideSecondary
        setViewController(primaryNavigationController, for: .primary)
        setViewController(supplementaryNavigationController, for: .supplementary)
        setViewController(secondaryNavigationController, for: .secondary)
    }
}

@MainActor
private final class SplitPrimaryViewController: ExampleDrawerViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Primary"
        view.backgroundColor = .systemGroupedBackground

        let titleLabel = UILabel()
        titleLabel.font = .preferredFont(forTextStyle: .title1)
        titleLabel.text = "Primary NavigationController"
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        let detailLabel = UILabel()
        detailLabel.font = .preferredFont(forTextStyle: .body)
        detailLabel.textColor = .secondaryLabel
        detailLabel.text = "The drawer gesture is attached to the tab bar controller."
        detailLabel.textAlignment = .center
        detailLabel.numberOfLines = 0

        let pushButton = UIButton(configuration: .filled())
        pushButton.configuration?.title = "Push child view"
        pushButton.addAction(
            UIAction { [weak self] _ in
                self?.navigationController?.pushViewController(
                    SplitPushedViewController(source: "Primary"),
                    animated: true
                )
            },
            for: .primaryActionTriggered
        )

        let stackView = UIStackView(arrangedSubviews: [titleLabel, detailLabel, pushButton])
        stackView.axis = .vertical
        stackView.spacing = 12
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            view.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: 20),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
}

@MainActor
private final class SplitSupplementaryViewController: ExampleDrawerViewController {
    private let tiledSplitBehaviorSwitch = UISwitch()
    private let twoBesideSecondarySwitch = UISwitch()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Split Settings"
        view.backgroundColor = .systemGroupedBackground

        let titleLabel = UILabel()
        titleLabel.font = .preferredFont(forTextStyle: .title1)
        titleLabel.text = "Split View Settings"
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        let detailLabel = UILabel()
        detailLabel.font = .preferredFont(forTextStyle: .body)
        detailLabel.textColor = .secondaryLabel
        detailLabel.text = "These controls update the containing split view controller directly."
        detailLabel.textAlignment = .center
        detailLabel.numberOfLines = 0

        tiledSplitBehaviorSwitch.isOn = splitViewController?.preferredSplitBehavior == .tile
        tiledSplitBehaviorSwitch.accessibilityLabel = "Tile split behavior"
        tiledSplitBehaviorSwitch.addTarget(
            self,
            action: #selector(tiledSplitBehaviorSwitchChanged),
            for: .valueChanged
        )

        twoBesideSecondarySwitch.isOn = splitViewController?.preferredDisplayMode == .twoBesideSecondary
        twoBesideSecondarySwitch.accessibilityLabel = "Two beside secondary"
        twoBesideSecondarySwitch.addTarget(
            self,
            action: #selector(twoBesideSecondarySwitchChanged),
            for: .valueChanged
        )

        let stackView = UIStackView(arrangedSubviews: [
            titleLabel,
            detailLabel,
            makeSwitchRow(
                title: "Tile split behavior",
                detail: "Use a tiled split layout.",
                control: tiledSplitBehaviorSwitch
            ),
            makeSwitchRow(
                title: "Two beside secondary",
                detail: "Show primary, supplementary, and secondary together.",
                control: twoBesideSecondarySwitch
            ),
        ])
        stackView.axis = .vertical
        stackView.spacing = 12
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            view.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: 20),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
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
    private func tiledSplitBehaviorSwitchChanged(_ sender: UISwitch) {
        splitViewController?.preferredSplitBehavior = sender.isOn ? .tile : .automatic
    }

    @objc
    private func twoBesideSecondarySwitchChanged(_ sender: UISwitch) {
        splitViewController?.preferredDisplayMode = sender.isOn ? .twoBesideSecondary : .oneBesideSecondary
    }
}

@MainActor
private final class SplitSecondaryViewController: ExampleDrawerViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Secondary"
        view.backgroundColor = .systemBlue.withAlphaComponent(0.12)

        let titleLabel = UILabel()
        titleLabel.font = .preferredFont(forTextStyle: .title1)
        titleLabel.text = "Secondary NavigationController"
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        let detailLabel = UILabel()
        detailLabel.font = .preferredFont(forTextStyle: .body)
        detailLabel.textColor = .secondaryLabel
        detailLabel.text = "The drawer gesture is also attached to the tab bar controller."
        detailLabel.textAlignment = .center
        detailLabel.numberOfLines = 0

        let pushButton = UIButton(configuration: .filled())
        pushButton.configuration?.title = "Push child view"
        pushButton.addAction(
            UIAction { [weak self] _ in
                self?.navigationController?.pushViewController(
                    SplitPushedViewController(source: "Secondary"),
                    animated: true
                )
            },
            for: .primaryActionTriggered
        )

        let stackView = UIStackView(arrangedSubviews: [titleLabel, detailLabel, pushButton])
        stackView.axis = .vertical
        stackView.spacing = 12
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            view.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: 20),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
}

@MainActor
private final class SplitPushedViewController: UIViewController {
    private let source: String

    init(source: String) {
        self.source = source
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Pushed"
        view.backgroundColor = .systemBackground

        let titleLabel = UILabel()
        titleLabel.font = .preferredFont(forTextStyle: .title1)
        titleLabel.text = "Pushed from \(source)"
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        let detailLabel = UILabel()
        detailLabel.font = .preferredFont(forTextStyle: .body)
        detailLabel.textColor = .secondaryLabel
        detailLabel.text = "Swipe right to test UINavigationController pop priority."
        detailLabel.textAlignment = .center
        detailLabel.numberOfLines = 0

        let popButton = UIButton(configuration: .tinted())
        popButton.configuration?.title = "Pop child view"
        popButton.addAction(
            UIAction { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            },
            for: .primaryActionTriggered
        )

        let stackView = UIStackView(arrangedSubviews: [titleLabel, detailLabel, popButton])
        stackView.axis = .vertical
        stackView.spacing = 12
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            view.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: 20),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
}
