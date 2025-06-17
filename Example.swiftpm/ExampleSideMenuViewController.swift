import UIKit

@MainActor
protocol ExampleSideMenuViewControllerDelegate: AnyObject {
    func exampleSideMenuViewControllerDidSelect(_ viewController: ExampleSideMenuViewController)
}

final class ExampleSideMenuViewController: UIViewController {
    let label: UILabel = UILabel()
    
    let button: UIButton = {
        if #available(iOS 26.0, *) {
            UIButton(configuration: .glass())
        } else {
            UIButton(configuration: .filled())
        }
    }()
    weak var delegate: (any ExampleSideMenuViewControllerDelegate)? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        
        label.text = "Hello, World!"
        button.configuration?.title = "Button"
        
        let stackView = UIStackView(
            arrangedSubviews: [
                label,
                button
            ]
        )
        if #available(iOS 26.0, *) {
            let effect = UIGlassEffect()
            let effectView = UIVisualEffectView(
                effect: effect
            )
            effectView.translatesAutoresizingMaskIntoConstraints = false
            effectView.layer.cornerRadius = 56
            view.addSubview(effectView)
            NSLayoutConstraint.activate([
                effectView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 10),
                effectView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -10),
                effectView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                effectView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10),
            ])
            
        }
        stackView.axis = .vertical
        stackView.spacing = 20
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

