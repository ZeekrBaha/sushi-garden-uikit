import XCTest
@testable import SushiGarden

final class InMemoryOrdersServiceTests: XCTestCase {
    func test_placeOrder_appendsOrderWithComputedTotal() {
        let service = InMemoryOrdersService()
        let product = Product(id: "idaho", name: "Айдахо маки", categoryId: "rolls",
                              weightGrams: 285, price: 810, imageName: "idaho", description: "")
        let items = [CartItem(product: product, quantity: 2)]
        let address = DeliveryAddress(city: "Воронеж", street: "Мира", building: "36")

        let order = service.placeOrder(items: items, address: address)

        XCTAssertEqual(order.total, 1620)
        XCTAssertEqual(order.status, .placed)
        XCTAssertEqual(service.orders.count, 1)
        XCTAssertEqual(service.orders.first?.id, order.id)
    }
}
