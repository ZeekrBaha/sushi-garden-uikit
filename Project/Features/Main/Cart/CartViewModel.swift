import Foundation
import Combine

final class CartViewModel {
    @Published private(set) var items: [CartItem] = []
    var totalPrice: Int { items.reduce(0) { $0 + $1.subtotal } }
    var isEmpty: Bool { items.isEmpty }

    var onCheckout: (() -> Void)?

    private let cart: CartServicing
    private var cancellables = Set<AnyCancellable>()

    init(cart: CartServicing) {
        self.cart = cart
        cart.itemsPublisher
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in self?.items = items }
            .store(in: &cancellables)
    }

    func setQuantity(_ quantity: Int, for productId: String) {
        cart.setQuantity(quantity, for: productId)
    }

    func remove(productId: String) {
        cart.remove(productId: productId)
    }

    func checkout() {
        onCheckout?()
    }
}
