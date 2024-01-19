import SwiftUI
import DrawerPresentation

@main
struct App: SwiftUI.App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> some UIViewController {
        TableViewController(style: .plain)
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        
    }
}

import UIKit
import SwiftUI

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
        
        drawerTransitionController.addDrawerGesture(to: self, drawerViewController: {
            UIHostingController(rootView: Text("Interactive side menu"))
        })
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = UIHostingController(rootView: Text("Hello, World!!"))
        vc.modalPresentationStyle = .custom
        vc.transitioningDelegate = drawerTransitionController
        present(vc, animated: true)
        
    }
}
