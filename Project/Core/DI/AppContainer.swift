import Foundation

final class AppContainer {
    let auth: AuthServicing
    let catalog: CatalogServicing
    let cart: CartServicing
    let orders: OrdersServicing

    init(
        auth: AuthServicing = InMemoryAuthService(),
        catalog: CatalogServicing = InMemoryCatalogService(),
        cart: CartServicing = InMemoryCartService(),
        orders: OrdersServicing = InMemoryOrdersService()
    ) {
        self.auth = auth
        self.catalog = catalog
        self.cart = cart
        self.orders = orders
    }
}
