import XCTest
import Combine
@testable import SushiGarden

final class InMemoryCartServiceTests: XCTestCase {
    private var cart: InMemoryCartService!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        cart = InMemoryCartService()
        cancellables = Set<AnyCancellable>()
    }

    private func product(_ id: String, _ price: Int) -> Product {
        Product(id: id, name: id, categoryId: "rolls", weightGrams: 100,
                price: price, imageName: id, description: "")
    }

    private func makeProduct(_ id: String, price: Int) -> Product {
        product(id, price)
    }

    func test_add_incrementsQuantityForSameProduct() {
        cart.add(product("idaho", 810))
        cart.add(product("idaho", 810))
        XCTAssertEqual(cart.items.count, 1)
        XCTAssertEqual(cart.items.first?.quantity, 2)
        XCTAssertEqual(cart.totalCount, 2)
        XCTAssertEqual(cart.totalPrice, 1620)
    }

    func test_setQuantity_toZero_removesItem() {
        cart.add(product("osaka", 740))
        cart.setQuantity(0, for: "osaka")
        XCTAssertTrue(cart.items.isEmpty)
    }

    func test_itemsPublisher_emitsOnChange() {
        var received: [[CartItem]] = []
        cart.itemsPublisher
            .sink { received.append($0) }
            .store(in: &cancellables)

        cart.add(product("hikari", 620))

        // One emission for the initial value, one after add.
        XCTAssertEqual(received.count, 2)
        XCTAssertEqual(received[0], [])
        XCTAssertFalse(received[1].isEmpty)
        XCTAssertEqual(received.last?.first?.product.id, "hikari")
    }

    func test_remove_removesItemFromCart() {
        let product = makeProduct("p1", price: 500)
        cart.add(product)
        cart.remove(productId: "p1")
        XCTAssertTrue(cart.items.isEmpty)
    }

    func test_clear_emptiesCart() {
        cart.add(makeProduct("p1", price: 500))
        cart.add(makeProduct("p2", price: 300))
        cart.clear()
        XCTAssertTrue(cart.items.isEmpty)
        XCTAssertEqual(cart.totalCount, 0)
        XCTAssertEqual(cart.totalPrice, 0)
    }

    func test_setQuantity_updatesQuantity() {
        let product = makeProduct("p1", price: 500)
        cart.add(product)
        cart.setQuantity(5, for: "p1")
        XCTAssertEqual(cart.items.first?.quantity, 5)
        XCTAssertEqual(cart.totalPrice, 2500)
    }

    func test_setQuantity_negative_isIgnored() {
        let product = makeProduct("p1", price: 500)
        cart.add(product)
        cart.setQuantity(-1, for: "p1")
        XCTAssertEqual(cart.items.count, 1)  // item still present
    }
}
