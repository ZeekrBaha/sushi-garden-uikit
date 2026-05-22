import XCTest
@testable import SushiGarden

final class CartItemTests: XCTestCase {
    private func makeProduct(price: Int) -> Product {
        Product(id: "p1", name: "Айдахо маки", categoryId: "rolls",
                weightGrams: 285, price: price, imageName: "idaho", description: "")
    }

    func test_subtotal_isPriceTimesQuantity() {
        let item = CartItem(product: makeProduct(price: 810), quantity: 3)
        XCTAssertEqual(item.subtotal, 2430)
    }

    func test_subtotal_singleQuantity_equalsPrice() {
        let item = CartItem(product: makeProduct(price: 620), quantity: 1)
        XCTAssertEqual(item.subtotal, 620)
    }
}
