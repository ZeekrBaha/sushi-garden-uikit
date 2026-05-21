import XCTest
import Combine
@testable import SushiGarden

final class CartViewModelTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()

    override func tearDown() {
        cancellables = []
        super.tearDown()
    }

    private func makeProduct(_ id: String = "p1", price: Int = 500) -> Product {
        Product(id: id, name: "Test", categoryId: "rolls",
                weightGrams: 200, price: price, imageName: "test", description: "")
    }

    func test_items_initiallyEmpty() {
        let sut = CartViewModel(cart: InMemoryCartService())
        XCTAssertTrue(sut.items.isEmpty)
    }

    func test_items_updatesWhenProductAdded() {
        let cart = InMemoryCartService()
        let sut = CartViewModel(cart: cart)
        cart.add(makeProduct())
        XCTAssertEqual(sut.items.count, 1)
    }

    func test_totalPrice_sumsSubtotals() {
        let cart = InMemoryCartService()
        let sut = CartViewModel(cart: cart)
        cart.add(makeProduct("p1", price: 500))
        cart.add(makeProduct("p2", price: 300))
        XCTAssertEqual(sut.totalPrice, 800)
    }

    func test_isEmpty_trueWhenNoItems() {
        let sut = CartViewModel(cart: InMemoryCartService())
        XCTAssertTrue(sut.isEmpty)
    }

    func test_isEmpty_falseWhenHasItems() {
        let cart = InMemoryCartService()
        let sut = CartViewModel(cart: cart)
        cart.add(makeProduct())
        XCTAssertFalse(sut.isEmpty)
    }

    func test_setQuantity_forwardsToService() {
        let cart = InMemoryCartService()
        let sut = CartViewModel(cart: cart)
        cart.add(makeProduct())
        sut.setQuantity(3, for: "p1")
        XCTAssertEqual(cart.items.first?.quantity, 3)
    }

    func test_remove_forwardsToService() {
        let cart = InMemoryCartService()
        let sut = CartViewModel(cart: cart)
        cart.add(makeProduct())
        sut.remove(productId: "p1")
        XCTAssertTrue(cart.items.isEmpty)
    }

    func test_checkout_firesOnCheckout() {
        let sut = CartViewModel(cart: InMemoryCartService())
        var called = false
        sut.onCheckout = { called = true }
        sut.checkout()
        XCTAssertTrue(called)
    }

    func test_items_publishesOnChange() {
        let cart = InMemoryCartService()
        let sut = CartViewModel(cart: cart)
        var count = 0
        sut.$items.dropFirst().sink { _ in count += 1 }.store(in: &cancellables)
        cart.add(makeProduct())
        XCTAssertEqual(count, 1)
    }
}
