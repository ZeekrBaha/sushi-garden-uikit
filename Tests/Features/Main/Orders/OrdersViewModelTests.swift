import XCTest
import Combine
@testable import SushiGarden

final class OrdersViewModelTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()

    override func tearDown() {
        cancellables = []
        super.tearDown()
    }

    private func drainMainQueue() {
        let exp = expectation(description: "main queue drained")
        DispatchQueue.main.async { exp.fulfill() }
        wait(for: [exp], timeout: 1.0)
    }

    private func makePlacedOrder(in service: InMemoryOrdersService) {
        let product = Product(id: "p1", name: "Roll", categoryId: "rolls",
                              weightGrams: 200, price: 800, imageName: "roll", description: "")
        let address = DeliveryAddress(city: "А", street: "Б", building: "1")
        _ = service.placeOrder(items: [CartItem(product: product, quantity: 1)], address: address)
    }

    func test_orders_initiallyEmpty() {
        let sut = OrdersViewModel(service: InMemoryOrdersService())
        XCTAssertTrue(sut.orders.isEmpty)
    }

    func test_initialOrders_populatedFromService() {
        let service = InMemoryOrdersService()
        makePlacedOrder(in: service)
        let sut = OrdersViewModel(service: service)
        XCTAssertEqual(sut.orders.count, 1)
    }

    func test_orders_updatesWhenServiceEmits() {
        let service = InMemoryOrdersService()
        let sut = OrdersViewModel(service: service)
        makePlacedOrder(in: service)
        drainMainQueue()
        XCTAssertEqual(sut.orders.count, 1)
    }

    func test_isEmpty_trueWhenNoOrders() {
        let sut = OrdersViewModel(service: InMemoryOrdersService())
        XCTAssertTrue(sut.isEmpty)
    }

    func test_isEmpty_falseWhenOrdersExist() {
        let service = InMemoryOrdersService()
        makePlacedOrder(in: service)
        let sut = OrdersViewModel(service: service)
        XCTAssertFalse(sut.isEmpty)
    }

    func test_orders_publishesOnChange() {
        let service = InMemoryOrdersService()
        let sut = OrdersViewModel(service: service)
        var count = 0
        sut.$orders.dropFirst().sink { _ in count += 1 }.store(in: &cancellables)
        makePlacedOrder(in: service)
        drainMainQueue()
        XCTAssertEqual(count, 1)
    }
}
