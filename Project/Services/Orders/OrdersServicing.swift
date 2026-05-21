import Foundation
import Combine

protocol OrdersServicing {
    var orders: [Order] { get }
    var ordersPublisher: AnyPublisher<[Order], Never> { get }
    func placeOrder(items: [CartItem], address: DeliveryAddress) -> Order
}
