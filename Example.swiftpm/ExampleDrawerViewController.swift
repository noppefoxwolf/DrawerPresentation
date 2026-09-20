import UIKit
import SwiftUI
import DrawerPresentation

@MainActor
class ExampleDrawerViewController: UIViewController, ExampleSideMenuViewControllerDelegate, DrawerInteractionDelegate {
    private lazy var drawerInteraction = DrawerInteraction(delegate: self)
    private let manualTransitionDelegate = DrawerTransitionController(drawerWidth: 300)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "line.3.horizontal"),
            primaryAction: UIAction { [weak self] _ in
                self?.drawerInteraction.present()
            }
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            systemItem: .search,
            primaryAction: UIAction { [weak self] _ in
                self?.presentDrawerManually()
            }
        )

        navigationController?.view.addInteraction(drawerInteraction)
    }

    func presentDrawerManually() {
        let viewController = UIHostingController(rootView: Text("Presented manually"))
        viewController.modalPresentationStyle = .custom
        viewController.transitioningDelegate = manualTransitionDelegate
        present(viewController, animated: true)
    }

    func exampleSideMenuViewControllerDidSelect(_ viewController: ExampleSideMenuViewController) {
        viewController.dismiss(animated: true)
        navigationController?.pushViewController(
            UIHostingController(rootView: Text("Child View")),
            animated: true
        )
    }

    func viewController(for interaction: DrawerInteraction) -> UIViewController {
        navigationController ?? self
    }

    func drawerInteraction(
        _ interaction: DrawerInteraction,
        widthForDrawer drawerViewController: UIViewController
    ) -> CGFloat {
        300
    }

    func drawerInteraction(
        _ interaction: DrawerInteraction,
        presentingViewControllerFor viewController: UIViewController
    ) -> UIViewController? {
        let sideMenuViewController = ExampleSideMenuViewController()
        sideMenuViewController.delegate = self
        return sideMenuViewController
    }
}

@MainActor
final class PlainViewController: ExampleDrawerViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "View"

        let titleLabel = UILabel()
        titleLabel.font = .preferredFont(forTextStyle: .largeTitle)
        titleLabel.text = "Plain View"
        titleLabel.textAlignment = .center

        let detailLabel = UILabel()
        detailLabel.font = .preferredFont(forTextStyle: .body)
        detailLabel.textColor = .secondaryLabel
        detailLabel.text = "Swipe right anywhere to open the drawer."
        detailLabel.textAlignment = .center
        detailLabel.numberOfLines = 0

        let stackView = UIStackView(arrangedSubviews: [titleLabel, detailLabel])
        stackView.axis = .vertical
        stackView.spacing = 12
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            view.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: 24),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
}

@MainActor
final class PageViewController: ExampleDrawerViewController, UIPageViewControllerDataSource {
    private let pages = [
        ExamplePageViewController(title: "Page 1", color: .systemBlue),
        ExamplePageViewController(title: "Page 2", color: .systemOrange),
    ]
    private let pageController = UIPageViewController(
        transitionStyle: .scroll,
        navigationOrientation: .horizontal
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Pages"

        pageController.dataSource = self
        addChild(pageController)
        pageController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pageController.view)
        NSLayoutConstraint.activate([
            pageController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            pageController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: pageController.view.bottomAnchor),
            view.trailingAnchor.constraint(equalTo: pageController.view.trailingAnchor),
        ])
        pageController.didMove(toParent: self)
        pageController.setViewControllers(
            [pages[0]],
            direction: .forward,
            animated: false
        )
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        guard let index = pages.firstIndex(where: { $0 === viewController }), index > 0 else {
            return nil
        }
        return pages[index - 1]
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        guard let index = pages.firstIndex(where: { $0 === viewController }), index + 1 < pages.count else {
            return nil
        }
        return pages[index + 1]
    }
}

@MainActor
private final class ExamplePageViewController: UIViewController {
    private let pageTitle: String
    private let color: UIColor

    init(title: String, color: UIColor) {
        pageTitle = title
        self.color = color
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = color.withAlphaComponent(0.15)

        let titleLabel = UILabel()
        titleLabel.font = .preferredFont(forTextStyle: .largeTitle)
        titleLabel.text = pageTitle
        titleLabel.textAlignment = .center

        let detailLabel = UILabel()
        detailLabel.font = .preferredFont(forTextStyle: .body)
        detailLabel.textColor = .secondaryLabel
        detailLabel.text = "Swipe horizontally to move between pages."
        detailLabel.textAlignment = .center
        detailLabel.numberOfLines = 0

        let stackView = UIStackView(arrangedSubviews: [titleLabel, detailLabel])
        stackView.axis = .vertical
        stackView.spacing = 12
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            view.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: 24),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
}
