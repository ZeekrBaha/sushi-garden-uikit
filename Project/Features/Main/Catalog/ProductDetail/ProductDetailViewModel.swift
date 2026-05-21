import Foundation

final class ProductDetailViewModel {
    let product: Product
    var onAddedToCart: (() -> Void)?

    private let cart: CartServicing

    init(product: Product, cart: CartServicing) {
        self.product = product
        self.cart = cart
    }

    func addToCart(quantity: Int) {
        for _ in 0..<quantity {
            cart.add(product)
        }
        onAddedToCart?()
    }
}
