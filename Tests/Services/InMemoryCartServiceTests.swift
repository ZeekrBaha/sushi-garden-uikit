import XCTest
import Combine
@testable import SushiGarden

final class InMemoryCartServiceTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()

    private func product(_ id: String, _ price: Int) -> Product {
        Product(id: id, name: id, categoryId: "rolls", weightGrams: 100,
                price: price, imageName: id, description: "")
    }

    func test_add_incrementsQuantityForSameProduct() {
        let cart = InMemoryCartService()
        cart.add(product("idaho", 810))
        cart.add(product("idaho", 810))
        XCTAssertEqual(cart.items.count, 1)
        XCTAssertEqual(cart.items.first?.quantity, 2)
        XCTAssertEqual(cart.totalCount, 2)
        XCTAssertEqual(cart.totalPrice, 1620)
    }

    func test_setQuantity_toZero_removesItem() {
        let cart = InMemoryCartService()
        cart.add(product("osaka", 740))
        cart.setQuantity(0, for: "osaka")
        XCTAssertTrue(cart.items.isEmpty)
    }

    func test_itemsPublisher_emitsOnChange() {
        let cart = InMemoryCartService()
        var received: [[CartItem]] = []
        cart.itemsPublisher
            .sink { received.append($0) }
            .store(in: &cancellables)

        cart.add(product("hikari", 620))

        // One emission for the initial value, one after add.
        XCTAssertEqual(received.count, 2)
        XCTAssertEqual(received.last?.first?.product.id, "hikari")
    }
}
