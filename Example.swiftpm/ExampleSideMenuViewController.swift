import UIKit

@MainActor
protocol ExampleSideMenuViewControllerDelegate: AnyObject {
    func exampleSideMenuViewControllerDidSelect(_ viewController: ExampleSideMenuViewController)
}

final class ExampleSideMenuViewController: UIViewController {
    let label: UILabel = UILabel()
    let button: UIButton = UIButton(configuration: .filled())
    private let materialView: UIVisualEffectView = {
        if #available(iOS 26.0, *) {
            return UIVisualEffectView(effect: UIGlassEffect(style: .clear))
        }
        return UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    }()
    private let hairlineView = UIView()
    weak var delegate: (any ExampleSideMenuViewControllerDelegate)? = nil

    private var deviceCornerRadius: CGFloat {
        switch traitCollection.userInterfaceIdiom {
        case .phone:
            56
        case .pad:
            24
        default:
            24
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        materialView.translatesAutoresizingMaskIntoConstraints = false
        materialView.isUserInteractionEnabled = false
        materialView.layer.cornerRadius = deviceCornerRadius
        materialView.layer.cornerCurve = .continuous
        materialView.layer.maskedCorners = [
            .layerMaxXMinYCorner,
            .layerMaxXMaxYCorner,
        ]
        materialView.clipsToBounds = true
        view.addSubview(materialView)
        NSLayoutConstraint.activate([
            materialView.topAnchor.constraint(equalTo: view.topAnchor),
            materialView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            materialView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            materialView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        hairlineView.backgroundColor = .separator
        hairlineView.isAccessibilityElement = false
        hairlineView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hairlineView)
        let hairlineWidthConstraint = hairlineView.widthAnchor.constraint(
            equalToConstant: 1 / view.traitCollection.displayScale
        )
        NSLayoutConstraint.activate([
            hairlineView.topAnchor.constraint(equalTo: view.topAnchor),
            hairlineView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hairlineView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hairlineWidthConstraint,
        ])
        
        label.text = "Hello, World!"
        button.configuration?.title = "Button"
        
        let stackView = UIStackView(
            arrangedSubviews: [
                label,
                button
            ]
        )
        stackView.axis = .vertical
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(
                equalTo: view.centerYAnchor
            ),
            stackView.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                constant: 20
            ),
            view.trailingAnchor.constraint(
                equalTo: stackView.safeAreaLayoutGuide.trailingAnchor,
                constant: 20
            ),
        ])
        
        button.addAction(UIAction { [unowned self] _ in
            delegate?.exampleSideMenuViewControllerDidSelect(self)
        }, for: .primaryActionTriggered)
    }
}
