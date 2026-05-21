import XCTest
import Combine
@testable import SushiGarden

final class InMemoryOrdersServiceTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()

    private func makeItems(price: Int, quantity: Int) -> [CartItem] {
        let product = Product(id: "p", name: "p", categoryId: "rolls",
                              weightGrams: 100, price: price, imageName: "p", description: "")
        return [CartItem(product: product, quantity: quantity)]
    }

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

    func test_ordersPublisher_emitsOnPlaceOrder() {
        let service = InMemoryOrdersService()
        var received: [[Order]] = []
        service.ordersPublisher.sink { received.append($0) }.store(in: &cancellables)

        _ = service.placeOrder(items: makeItems(price: 500, quantity: 1),
                                address: DeliveryAddress(city: "А", street: "Б", building: "1"))

        XCTAssertEqual(received.count, 2)
        XCTAssertEqual(received[0], [])
        XCTAssertEqual(received[1].count, 1)
    }
}
