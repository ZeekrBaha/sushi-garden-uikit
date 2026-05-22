import XCTest
@testable import SushiGarden

final class CartCoordinatorTests: XCTestCase {
    private func makeSUT(
        onSwitchToOrders: @escaping () -> Void = {}
    ) -> (CartCoordinator, UINavigationController) {
        let nav = UINavigationController()
        let sut = CartCoordinator(
            navigationController: nav,
            container: AppContainer(),
            onSwitchToOrders: onSwitchToOrders)
        return (sut, nav)
    }

    func test_start_setsCartViewControllerAsRoot() {
        let (sut, nav) = makeSUT()
        sut.start()
        XCTAssertTrue(nav.topViewController is CartViewController)
    }

    func test_onCheckout_pushesCheckoutViewController() {
        let (sut, nav) = makeSUT()
        sut.start()
        let cartVC = nav.topViewController as? CartViewController
        cartVC?.viewModel.checkout()
        XCTAssertTrue(nav.viewControllers.last is CheckoutViewController)
        _ = sut
    }

    func test_onOrderPlaced_callsSwitchToOrders() {
        var switched = false
        let (sut, nav) = makeSUT(onSwitchToOrders: { switched = true })
        sut.start()
        let cartVC = nav.topViewController as? CartViewController
        cartVC?.viewModel.checkout()
        let checkoutVC = nav.viewControllers.last as? CheckoutViewController
        checkoutVC?.viewModel.onOrderPlaced?()
        XCTAssertTrue(switched)
    }
}
