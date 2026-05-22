import XCTest
@testable import SushiGarden

final class MainTabCoordinatorTests: XCTestCase {
    private func makeSUT() -> MainTabCoordinator {
        MainTabCoordinator(container: AppContainer())
    }

    func test_start_creates5Tabs() {
        let sut = makeSUT()
        sut.start()
        XCTAssertEqual(sut.tabBarController.viewControllers?.count, 5)
    }

    func test_start_firstTabIsNavigationController() {
        let sut = makeSUT()
        sut.start()
        XCTAssertTrue(sut.tabBarController.viewControllers?.first is UINavigationController)
    }

    func test_start_firstTabContainsCatalogViewController() {
        let sut = makeSUT()
        sut.start()
        let nav = sut.tabBarController.viewControllers?.first as? UINavigationController
        XCTAssertTrue(nav?.topViewController is CatalogViewController)
    }

    func test_cartBadge_updatesWhenItemAddedToCart() {
        let cart = InMemoryCartService()
        let container = AppContainer(cart: cart)
        let sut = MainTabCoordinator(container: container)
        sut.start()
        let product = InMemoryCatalogService().allProducts().first!
        cart.add(product)
        // Cart is tab index 3
        XCTAssertEqual(sut.tabBarController.viewControllers?[3].tabBarItem.badgeValue, "1")
    }

    func test_cartBadge_clearsWhenCartIsEmpty() {
        let cart = InMemoryCartService()
        let container = AppContainer(cart: cart)
        let sut = MainTabCoordinator(container: container)
        sut.start()
        let product = InMemoryCatalogService().allProducts().first!
        cart.add(product)
        cart.clear()
        XCTAssertNil(sut.tabBarController.viewControllers?[3].tabBarItem.badgeValue)
    }

    func test_start_cartTabIsNavigationController() {
        let sut = makeSUT()
        sut.start()
        XCTAssertTrue(sut.tabBarController.viewControllers?[3] is UINavigationController)
    }

    func test_start_cartTabContainsCartViewController() {
        let sut = makeSUT()
        sut.start()
        let nav = sut.tabBarController.viewControllers?[3] as? UINavigationController
        XCTAssertTrue(nav?.topViewController is CartViewController)
    }

    func test_start_ordersTabContainsOrdersViewController() {
        let sut = makeSUT()
        sut.start()
        let nav = sut.tabBarController.viewControllers?[1] as? UINavigationController
        XCTAssertTrue(nav?.topViewController is OrdersViewController)
    }

    func test_start_promotionsTabContainsPromotionsViewController() {
        let sut = makeSUT()
        sut.start()
        let nav = sut.tabBarController.viewControllers?[2] as? UINavigationController
        XCTAssertTrue(nav?.topViewController is PromotionsViewController)
    }

    func test_start_profileTabContainsProfileViewController() {
        let sut = makeSUT()
        sut.start()
        let nav = sut.tabBarController.viewControllers?[4] as? UINavigationController
        XCTAssertTrue(nav?.topViewController is ProfileViewController)
    }
}
