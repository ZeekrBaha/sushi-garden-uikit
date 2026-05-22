import UIKit

final class CartCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []

    let navigationController: UINavigationController
    private let container: AppContainer
    private let onSwitchToOrders: () -> Void

    init(navigationController: UINavigationController = UINavigationController(),
         container: AppContainer,
         onSwitchToOrders: @escaping () -> Void) {
        self.navigationController = navigationController
        self.container = container
        self.onSwitchToOrders = onSwitchToOrders
    }

    func start() {
        let vm = CartViewModel(cart: container.cart)
        vm.onCheckout = { [weak self] in self?.showCheckout() }
        let vc = CartViewController(viewModel: vm)
        navigationController.setViewControllers([vc], animated: false)
    }

    private func showCheckout() {
        let vm = CheckoutViewModel(
            items: container.cart.items,
            totalPrice: container.cart.totalPrice,
            orders: container.orders,
            cart: container.cart)
        vm.onOrderPlaced = { [weak self] in self?.orderPlaced() }
        let vc = CheckoutViewController(viewModel: vm)
        navigationController.pushViewController(vc, animated: true)
    }

    private func orderPlaced() {
        navigationController.popToRootViewController(animated: false)
        onSwitchToOrders()
    }
}
