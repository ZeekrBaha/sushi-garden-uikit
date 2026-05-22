import XCTest
@testable import SushiGarden

final class CatalogCoordinatorTests: XCTestCase {
    private func makeSUT() -> (CatalogCoordinator, UINavigationController) {
        let nav = UINavigationController()
        let container = AppContainer()
        let sut = CatalogCoordinator(navigationController: nav, container: container)
        return (sut, nav)
    }

    func test_start_setsCatalogViewControllerAsRoot() {
        let (sut, nav) = makeSUT()
        sut.start()
        XCTAssertTrue(nav.topViewController is CatalogViewController)
    }

    func test_afterSelectProduct_pushesProductDetailViewController() {
        let (sut, nav) = makeSUT()
        sut.start()
        let catalogVC = nav.topViewController as? CatalogViewController
        let product = InMemoryCatalogService().allProducts().first!
        catalogVC?.viewModel.selectProduct(product)
        XCTAssertTrue(nav.viewControllers.last is ProductDetailViewController)
    }
}
