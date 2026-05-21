import XCTest
@testable import SushiGarden

final class ProductDetailViewModelTests: XCTestCase {
    private func makeProduct() -> Product {
        Product(id: "p1", name: "Хикари", categoryId: "rolls",
                weightGrams: 255, price: 620, imageName: "hikari", description: "Light roll")
    }

    func test_product_isExposed() {
        let product = makeProduct()
        let sut = ProductDetailViewModel(product: product, cart: InMemoryCartService())
        XCTAssertEqual(sut.product, product)
    }

    func test_addToCart_withQuantityOne_addsOneItem() {
        let cart = InMemoryCartService()
        let sut = ProductDetailViewModel(product: makeProduct(), cart: cart)
        sut.addToCart(quantity: 1)
        XCTAssertEqual(cart.totalCount, 1)
    }

    func test_addToCart_withQuantityThree_addsThreeItems() {
        let cart = InMemoryCartService()
        let sut = ProductDetailViewModel(product: makeProduct(), cart: cart)
        sut.addToCart(quantity: 3)
        XCTAssertEqual(cart.totalCount, 3)
    }

    func test_addToCart_callsOnAddedToCart() {
        let sut = ProductDetailViewModel(product: makeProduct(), cart: InMemoryCartService())
        var called = false
        sut.onAddedToCart = { called = true }
        sut.addToCart(quantity: 1)
        XCTAssertTrue(called)
    }
}
