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
    
    let drawerTransitionController = DrawerTransitionController()
    
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
        
        drawerTransitionController.addDrawerGesture(
            to: navigationController!,
            drawerViewController: {
                let vc = ExampleSideMenuViewController()
                vc.delegate = self
                return vc
            }
        )
        
        navigationItem.leftBarButtonItems = [
            UIBarButtonItem(
                image: UIImage(systemName: "line.3.horizontal"),
                primaryAction: UIAction { [unowned self] _ in
                    drawerTransitionController.presentRegisteredDrawer()
                }
            )
        ]
        
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(
                systemItem: .search,
                primaryAction: UIAction { [unowned self] _ in
                    let vc = UIHostingController(rootView: Text("Hello, World!!"))
                    vc.modalPresentationStyle = .custom
                    vc.transitioningDelegate = drawerTransitionController
                    present(vc, animated: true)
                }
            ),
        ]
    }
    
    func exampleSideMenuViewControllerDidSelect(_ viewController: ExampleSideMenuViewController) {
        viewController.dismiss(animated: true)
        
        let vc = UIHostingController(rootView: Text("Child View"))
        navigationController?.pushViewController(vc, animated: true)
    }
}

