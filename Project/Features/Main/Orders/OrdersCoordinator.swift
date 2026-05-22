import UIKit

final class OrdersCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []

    let navigationController: UINavigationController
    private let container: AppContainer

    init(navigationController: UINavigationController = UINavigationController(),
         container: AppContainer) {
        self.navigationController = navigationController
        self.container = container
    }

    func start() {
        let vm = OrdersViewModel(service: container.orders)
        let vc = OrdersViewController(viewModel: vm)
        navigationController.setViewControllers([vc], animated: false)
    }
}
