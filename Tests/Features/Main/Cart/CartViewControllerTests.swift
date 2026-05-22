import XCTest
@testable import SushiGarden

final class CartViewControllerTests: XCTestCase {
    private func makeSUT() -> CartViewController {
        CartViewController(viewModel: CartViewModel(cart: InMemoryCartService()))
    }

    func test_loadsWithoutCrashing() {
        let sut = makeSUT()
        sut.loadViewIfNeeded()
        XCTAssertNotNil(sut.view)
    }

    func test_viewModel_isExposed() {
        let vm = CartViewModel(cart: InMemoryCartService())
        let sut = CartViewController(viewModel: vm)
        XCTAssertTrue(sut.viewModel === vm)
    }
}
