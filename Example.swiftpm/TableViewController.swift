import UIKit
import SwiftUI
import DrawerPresentation

enum Section: Int {
    case items
}

struct Item: Hashable {
    let id: UUID = UUID()
}

final class TableViewController: UITableViewController, ExampleSideMenuViewControllerDelegate {
    lazy var dataSource = UITableViewDiffableDataSource<Section, Item>(
        tableView: tableView,
        cellProvider: { [unowned self] (tableView, indexPath, item) in
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            cell.contentConfiguration = UIHostingConfiguration(content: {
                Text("Hello, World!")
            })
            return cell
        }
    )
    
    var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        _ = dataSource
        
        snapshot.appendSections([.items])
        snapshot.appendItems((0..<100).map({ _ in Item() }), toSection: .items)
        
        dataSource.apply(snapshot)
        
        let interaction = DrawerInteraction(delegate: self)
        navigationController!.view.addInteraction(interaction)
        
        navigationItem.leftBarButtonItems = [
            UIBarButtonItem(
                image: UIImage(systemName: "line.3.horizontal"),
                primaryAction: UIAction { _ in
                    interaction.present()
                }
            )
        ]
        
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(
                systemItem: .search,
                primaryAction: UIAction { [unowned self] _ in
                    presentDrawerManually()
                }
            ),
        ]
    }
    
    let manualTransitionDelegate = DrawerTransitionController(drawerWidth: 300)
    func presentDrawerManually() {
        let vc = UIHostingController(rootView: Text("Hello, World!!"))
        vc.modalPresentationStyle = .custom
        vc.transitioningDelegate = manualTransitionDelegate
        present(vc, animated: true)
    }
    
    func exampleSideMenuViewControllerDidSelect(_ viewController: ExampleSideMenuViewController) {
        viewController.dismiss(animated: true)
        
        let vc = UIHostingController(rootView: Text("Child View"))
        navigationController?.pushViewController(vc, animated: true)
    }
}


extension TableViewController: DrawerInteractionDelegate {
    func viewController(for interaction: DrawerInteraction) -> UIViewController {
        navigationController!
    }
    
    func drawerInteraction(_ interaction: DrawerInteraction, widthForDrawer drawerViewController: UIViewController) -> CGFloat {
        300
    }
    
    func drawerInteraction(_ interaction: DrawerInteraction, presentingViewControllerFor viewController: UIViewController) -> UIViewController? {
        let vc = ExampleSideMenuViewController()
        vc.delegate = self
        return vc
    }
}
