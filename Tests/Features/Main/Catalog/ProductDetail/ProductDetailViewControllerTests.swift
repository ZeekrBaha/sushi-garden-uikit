import XCTest
@testable import SushiGarden

final class ProductDetailViewControllerTests: XCTestCase {
    private func makeSUT() -> ProductDetailViewController {
        let product = Product(id: "p1", name: "Хикари", categoryId: "rolls",
                              weightGrams: 255, price: 620, imageName: "hikari", description: "")
        let vm = ProductDetailViewModel(product: product, cart: InMemoryCartService())
        return ProductDetailViewController(viewModel: vm)
    }

    func test_loadsWithoutCrashing() {
        let sut = makeSUT()
        sut.loadViewIfNeeded()
        XCTAssertNotNil(sut.view)
    }

    func test_viewModel_isExposed() {
        let product = Product(id: "p2", name: "Осака", categoryId: "rolls",
                              weightGrams: 275, price: 740, imageName: "osaka", description: "")
        let vm = ProductDetailViewModel(product: product, cart: InMemoryCartService())
        let sut = ProductDetailViewController(viewModel: vm)
        XCTAssertTrue(sut.viewModel === vm)
    }
}
