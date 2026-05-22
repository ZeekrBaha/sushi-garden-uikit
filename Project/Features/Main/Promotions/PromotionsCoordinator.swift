import UIKit

final class PromotionsCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    let navigationController: UINavigationController

    init(navigationController: UINavigationController = UINavigationController()) {
        self.navigationController = navigationController
    }

    func start() {
        let vc = PromotionsViewController()
        navigationController.setViewControllers([vc], animated: false)
    }
}
