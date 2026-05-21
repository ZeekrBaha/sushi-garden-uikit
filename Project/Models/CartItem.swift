struct CartItem: Identifiable, Equatable, Hashable {
    let product: Product
    var quantity: Int

    var id: String { product.id }
    var subtotal: Int { product.price * quantity }
}
