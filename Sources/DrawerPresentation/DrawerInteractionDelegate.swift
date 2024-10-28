import UIKit

@MainActor
public protocol DrawerInteractionDelegate: AnyObject, Sendable {
    func drawerInteraction(_ interaction: DrawerInteraction, widthForDrawer drawerViewController: UIViewController) -> CGFloat
    func drawerInteraction(_ interaction: DrawerInteraction, presentingViewControllerFor viewController: UIViewController) -> UIViewController?
    func viewController(for interaction: DrawerInteraction) -> UIViewController
}
