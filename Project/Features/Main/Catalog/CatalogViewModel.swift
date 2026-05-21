import Foundation
import Combine

final class CatalogViewModel {
    @Published private(set) var selectedCategoryId: String
    @Published private(set) var displayedProducts: [Product]

    var onSelectProduct: ((Product) -> Void)?

    private let catalog: CatalogServicing
    private let cart: CartServicing

    init(catalog: CatalogServicing, cart: CartServicing) {
        self.catalog = catalog
        self.cart = cart
        let firstId = catalog.categories().first?.id ?? ""
        self.selectedCategoryId = firstId
        self.displayedProducts = catalog.products(in: firstId)
    }

    var categories: [Category] { catalog.categories() }

    func selectCategory(_ id: String) {
        selectedCategoryId = id
        displayedProducts = catalog.products(in: id)
    }

    func addToCart(_ product: Product) {
        cart.add(product)
    }

    func selectProduct(_ product: Product) {
        onSelectProduct?(product)
    }
}
