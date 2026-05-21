import XCTest
@testable import SushiGarden

final class OrdersCoordinatorTests: XCTestCase {
    private func makeSUT() -> (OrdersCoordinator, UINavigationController) {
        let nav = UINavigationController()
        let sut = OrdersCoordinator(navigationController: nav, container: AppContainer())
        return (sut, nav)
    }

    func test_start_setsOrdersViewControllerAsRoot() {
        let (sut, nav) = makeSUT()
        sut.start()
        XCTAssertTrue(nav.topViewController is OrdersViewController)
    }
}
