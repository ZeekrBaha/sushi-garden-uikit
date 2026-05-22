import Foundation
import Combine

final class InMemoryOrdersService: OrdersServicing {
    private let subject = CurrentValueSubject<[Order], Never>([])

    var orders: [Order] { subject.value }
    var ordersPublisher: AnyPublisher<[Order], Never> { subject.eraseToAnyPublisher() }

    @discardableResult
    func placeOrder(items: [CartItem], address: DeliveryAddress) -> Order {
        let total = items.reduce(0) { $0 + $1.subtotal }
        let order = Order(id: UUID().uuidString, items: items, total: total,
                          createdAt: Date(), status: .placed)
        subject.send(subject.value + [order])
        return order
    }
}
