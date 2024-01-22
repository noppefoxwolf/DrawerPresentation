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
        UINavigationController(rootViewController: TableViewController(style: .plain))
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        
    }
}

