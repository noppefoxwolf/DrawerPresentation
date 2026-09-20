import UIKit

@MainActor
final class ExampleSplitViewController: UISplitViewController {
    private let primaryNavigationController = UINavigationController(
        rootViewController: SplitPrimaryViewController()
    )
    private let secondaryNavigationController = UINavigationController(
        rootViewController: SplitSecondaryViewController()
    )

    init() {
        super.init(style: .doubleColumn)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setViewController(primaryNavigationController, for: .primary)
        setViewController(secondaryNavigationController, for: .secondary)
        preferredDisplayMode = .oneBesideSecondary
        preferredSplitBehavior = .tile
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
        detailLabel.text = "The drawer gesture is attached to this navigation controller."
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
        detailLabel.text = "The drawer gesture is also attached to this navigation controller."
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
