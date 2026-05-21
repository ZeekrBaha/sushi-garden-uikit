import UIKit

final class CatalogCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []

    let navigationController: UINavigationController
    private let container: AppContainer

    init(navigationController: UINavigationController = UINavigationController(),
         container: AppContainer) {
        self.navigationController = navigationController
        self.container = container
    }

    func start() {
        let vm = CatalogViewModel(catalog: container.catalog, cart: container.cart)
        vm.onSelectProduct = { [weak self] product in self?.showDetail(product) }
        let vc = CatalogViewController(viewModel: vm)
        navigationController.setViewControllers([vc], animated: false)
    }

    private func showDetail(_ product: Product) {
        let vm = ProductDetailViewModel(product: product, cart: container.cart)
        vm.onAddedToCart = { [weak self] in
            self?.navigationController.popViewController(animated: true)
        }
        let vc = ProductDetailViewController(viewModel: vm)
        navigationController.pushViewController(vc, animated: true)
    }
}
