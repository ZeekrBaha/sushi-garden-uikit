import XCTest
@testable import SushiGarden

final class ProductCellTests: XCTestCase {
    private func makeProduct() -> Product {
        Product(id: "p1", name: "Хикари", categoryId: "rolls",
                weightGrams: 255, price: 620, imageName: "hikari", description: "Test roll")
    }

    func test_configure_setsNameLabel() {
        let sut = ProductCell()
        sut.configure(with: makeProduct())
        XCTAssertEqual(sut.nameLabel.text, "Хикари")
    }

    func test_configure_setsWeightLabel_withGramsUnit() {
        let sut = ProductCell()
        sut.configure(with: makeProduct())
        XCTAssertEqual(sut.weightLabel.text, "255 г")
    }

    func test_configure_setsPriceLabel_withRublesUnit() {
        let sut = ProductCell()
        sut.configure(with: makeProduct())
        XCTAssertEqual(sut.priceLabel.text, "620 ₽")
    }

    func test_onAddTapped_isCalled() {
        let sut = ProductCell()
        sut.configure(with: makeProduct())
        var called = false
        sut.onAddTapped = { called = true }
        sut.simulateAddTap()
        XCTAssertTrue(called)
    }
}
