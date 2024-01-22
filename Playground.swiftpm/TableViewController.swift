import UIKit
import SwiftUI
import DrawerPresentation

enum Section: Int {
    case items
}

struct Item: Hashable {
    let id: UUID = UUID()
}

class TableViewController: UITableViewController {
    
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
        
        drawerTransitionController.addDrawerGesture(to: navigationController!, drawerViewController: {
            UIHostingController(rootView: Text("Interactive side menu"))
        })
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "line.3.horizontal.circle"),
            primaryAction: UIAction { [unowned self] _ in
                drawerTransitionController.presentRegisteredDrawer()
            }
        )
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = UIHostingController(rootView: Text("Hello, World!!"))
        vc.modalPresentationStyle = .custom
        vc.transitioningDelegate = drawerTransitionController
        present(vc, animated: true)
        
    }
}
