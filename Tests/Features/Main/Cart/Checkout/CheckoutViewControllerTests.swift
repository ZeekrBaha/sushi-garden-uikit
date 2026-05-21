import XCTest
@testable import SushiGarden

final class CheckoutViewControllerTests: XCTestCase {
    private func makeSUT() -> CheckoutViewController {
        let items = [CartItem(
            product: Product(id: "p1", name: "Тест", categoryId: "rolls",
                             weightGrams: 200, price: 500, imageName: "", description: ""),
            quantity: 1)]
        let vm = CheckoutViewModel(items: items, totalPrice: 500,
                                   orders: InMemoryOrdersService(),
                                   cart: InMemoryCartService())
        return CheckoutViewController(viewModel: vm)
    }

    func test_loadsWithoutCrashing() {
        let sut = makeSUT()
        sut.loadViewIfNeeded()
        XCTAssertNotNil(sut.view)
    }

    func test_viewModel_isExposed() {
        let items = [CartItem(
            product: Product(id: "p2", name: "Осака", categoryId: "rolls",
                             weightGrams: 275, price: 740, imageName: "", description: ""),
            quantity: 2)]
        let vm = CheckoutViewModel(items: items, totalPrice: 1480,
                                   orders: InMemoryOrdersService(),
                                   cart: InMemoryCartService())
        let sut = CheckoutViewController(viewModel: vm)
        XCTAssertTrue(sut.viewModel === vm)
    }
}
