import Foundation
import Combine

final class OrdersViewModel {
    @Published private(set) var orders: [Order] = []
    var isEmpty: Bool { orders.isEmpty }

    private let service: OrdersServicing
    private var cancellables = Set<AnyCancellable>()

    init(service: OrdersServicing) {
        self.service = service
        self.orders = service.orders
        service.ordersPublisher
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] orders in self?.orders = orders }
            .store(in: &cancellables)
    }
}
