import UIKit

@MainActor
protocol ExampleSideMenuViewControllerDelegate: AnyObject {
    func exampleSideMenuViewControllerDidSelect(_ viewController: ExampleSideMenuViewController)
}

final class ExampleSideMenuViewController: UIViewController {
    let label: UILabel = UILabel()
    let button: UIButton = UIButton(configuration: .filled())
    weak var delegate: (any ExampleSideMenuViewControllerDelegate)? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
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

