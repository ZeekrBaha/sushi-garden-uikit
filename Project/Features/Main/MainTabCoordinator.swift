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
        catalogNav.tabBarItem = UITabBarItem(title: "Каталог",
                                             image: UIImage(systemName: "fork.knife"), tag: 0)

        let ordersVC = makePlaceholder(title: "Заказы", systemImage: "list.bullet", tag: 1)
        let promotionsVC = makePlaceholder(title: "Акции", systemImage: "tag", tag: 2)
        let cartVC = makePlaceholder(title: "Корзина", systemImage: "bag", tag: 3)
        let profileVC = makePlaceholder(title: "Профиль", systemImage: "person", tag: 4)

        tabBarController.viewControllers = [catalogNav, ordersVC, promotionsVC, cartVC, profileVC]
        tabBarController.tabBar.barTintColor = AppColor.surface
        tabBarController.tabBar.tintColor = AppColor.textPrimary
        tabBarController.tabBar.unselectedItemTintColor = AppColor.inactive

        bindCartBadge()
    }

    private func makePlaceholder(title: String, systemImage: String, tag: Int) -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = AppColor.background
        vc.tabBarItem = UITabBarItem(title: title, image: UIImage(systemName: systemImage), tag: tag)
        return vc
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
