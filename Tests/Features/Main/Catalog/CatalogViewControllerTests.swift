import XCTest
@testable import SushiGarden

final class CatalogViewControllerTests: XCTestCase {
    private func makeSUT() -> CatalogViewController {
        let vm = CatalogViewModel(catalog: InMemoryCatalogService(), cart: InMemoryCartService())
        return CatalogViewController(viewModel: vm)
    }

    func test_loadsWithoutCrashing() {
        let sut = makeSUT()
        sut.loadViewIfNeeded()
        XCTAssertNotNil(sut.view)
    }

    func test_viewModel_isExposed() {
        let vm = CatalogViewModel(catalog: InMemoryCatalogService(), cart: InMemoryCartService())
        let sut = CatalogViewController(viewModel: vm)
        XCTAssertTrue(sut.viewModel === vm)
    }
}
