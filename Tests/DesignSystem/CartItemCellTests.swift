import XCTest
@testable import SushiGarden

final class CartItemCellTests: XCTestCase {
    private func makeItem(quantity: Int = 2) -> CartItem {
        CartItem(
            product: Product(id: "p1", name: "Хикари", categoryId: "rolls",
                             weightGrams: 255, price: 620, imageName: "hikari", description: ""),
            quantity: quantity)
    }

    func test_configure_setsNameLabel() {
        let sut = CartItemCell()
        sut.configure(with: makeItem())
        XCTAssertEqual(sut.nameLabel.text, "Хикари")
    }

    func test_configure_setPriceLabel_asSubtotal() {
        let sut = CartItemCell()
        sut.configure(with: makeItem(quantity: 2))
        XCTAssertEqual(sut.priceLabel.text, "1240 ₽") // 620 × 2
    }

    func test_onQuantityChanged_calledWhenStepperIncrements() {
        let sut = CartItemCell()
        sut.configure(with: makeItem(quantity: 1))
        var received: Int?
        sut.onQuantityChanged = { received = $0 }
        sut.simulateIncrementTap()
        XCTAssertEqual(received, 2)
    }
}
