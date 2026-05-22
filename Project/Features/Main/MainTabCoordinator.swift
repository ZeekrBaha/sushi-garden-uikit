import UIKit
import Combine

final class MainTabCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []

    let tabBarController: UITabBarController
    private let container: AppContainer
    private var cancellables = Set<AnyCancellable>()

    init(container: AppContainer) {
        self.container = container
        self.tabBarController = UITabBarController()
    }

    func start() {
        let catalogNav = UINavigationController()
        catalogNav.navigationBar.isHidden = true
        let catalogCoordinator = CatalogCoordinator(navigationController: catalogNav, container: container)
        addChild(catalogCoordinator)
        catalogCoordinator.start()
        catalogNav.tabBarItem = UITabBarItem(
            title: "Каталог", image: UIImage(systemName: "fork.knife"), tag: 0)

        let ordersNav = UINavigationController()
        let ordersCoordinator = OrdersCoordinator(navigationController: ordersNav, container: container)
        addChild(ordersCoordinator)
        ordersCoordinator.start()
        ordersNav.tabBarItem = UITabBarItem(
            title: "Заказы", image: UIImage(systemName: "list.bullet"), tag: 1)

        let promotionsNav = UINavigationController()
        let promotionsCoordinator = PromotionsCoordinator(navigationController: promotionsNav)
        addChild(promotionsCoordinator)
        promotionsCoordinator.start()
        promotionsNav.tabBarItem = UITabBarItem(
            title: "Акции", image: UIImage(systemName: "tag"), tag: 2)

        let cartNav = UINavigationController()
        cartNav.navigationBar.isHidden = true
        let cartCoordinator = CartCoordinator(
            navigationController: cartNav,
            container: container,
            onSwitchToOrders: { [weak self] in
                self?.tabBarController.selectedIndex = 1
            })
        addChild(cartCoordinator)
        cartCoordinator.start()
        cartNav.tabBarItem = UITabBarItem(
            title: "Корзина", image: UIImage(systemName: "bag"), tag: 3)

        let profileNav = UINavigationController()
        let profileCoordinator = ProfileCoordinator(
            navigationController: profileNav,
            container: container,
            onLogout: { [weak self] in self?.handleLogout() })
        addChild(profileCoordinator)
        profileCoordinator.start()
        profileNav.tabBarItem = UITabBarItem(
            title: "Профиль", image: UIImage(systemName: "person"), tag: 4)

        tabBarController.viewControllers = [catalogNav, ordersNav, promotionsNav, cartNav, profileNav]
        tabBarController.tabBar.barTintColor = AppColor.surface
        tabBarController.tabBar.tintColor = AppColor.textPrimary
        tabBarController.tabBar.unselectedItemTintColor = AppColor.inactive

        bindCartBadge()
    }

    private func handleLogout() {
        // auth.logout() was already called by ProfileViewModel; AppCoordinator handles the transition
    }

    private func bindCartBadge() {
        container.cart.itemsPublisher
            .map { items -> String? in
                let count = items.reduce(0) { $0 + $1.quantity }
                return count > 0 ? "\(count)" : nil
            }
            .sink { [weak self] badge in
                self?.tabBarController.viewControllers?[3].tabBarItem.badgeValue = badge
            }
            .store(in: &cancellables)
    }
}
