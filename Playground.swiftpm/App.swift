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
        //TableViewController(style: .plain)
        PageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        
    }
}

