import Foundation
import Combine

protocol CartServicing {
    var items: [CartItem] { get }
    var itemsPublisher: AnyPublisher<[CartItem], Never> { get }
    var totalCount: Int { get }
    var totalPrice: Int { get }
    func add(_ product: Product)
    func setQuantity(_ quantity: Int, for productId: String)
    func remove(productId: String)
    func clear()
}

final class InMemoryCartService: CartServicing {
    private let subject = CurrentValueSubject<[CartItem], Never>([])

    var items: [CartItem] { subject.value }
    var itemsPublisher: AnyPublisher<[CartItem], Never> { subject.eraseToAnyPublisher() }
    var totalCount: Int { items.reduce(0) { $0 + $1.quantity } }
    var totalPrice: Int { items.reduce(0) { $0 + $1.subtotal } }

    func add(_ product: Product) {
        var current = subject.value
        if let index = current.firstIndex(where: { $0.product.id == product.id }) {
            current[index].quantity += 1
        } else {
            current.append(CartItem(product: product, quantity: 1))
        }
        subject.send(current)
    }

    func setQuantity(_ quantity: Int, for productId: String) {
        guard quantity >= 0 else { return }  // ignore invalid negative quantities
        var current = subject.value
        guard let index = current.firstIndex(where: { $0.product.id == productId }) else { return }
        if quantity == 0 { current.remove(at: index) } else { current[index].quantity = quantity }
        subject.send(current)
    }

    func remove(productId: String) {
        subject.send(subject.value.filter { $0.product.id != productId })
    }

    func clear() {
        subject.send([])
    }
}
