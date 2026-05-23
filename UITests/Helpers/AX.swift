import Foundation

enum AX {
    enum Splash {
        static let view = "splash.view"
    }
    enum Login {
        static let email = "login.email"
        static let password = "login.password"
        static let loginButton = "login.loginButton"
        static let registerLink = "login.registerLink"
        static let authError = "login.authError"
    }
    enum Register {
        static let name = "register.name"
        static let email = "register.email"
        static let password = "register.password"
        static let consent = "register.consent"
        static let registerButton = "register.registerButton"
        static let loginLink = "register.loginLink"
        static let authError = "register.authError"
    }
    enum Catalog {
        static func category(_ id: String) -> String { "catalog.category.\(id)" }
        static func product(_ id: String) -> String { "catalog.product.\(id)" }
        static func addButton(_ id: String) -> String { "catalog.add.\(id)" }
        static let empty = "catalog.empty"
    }
    enum Detail {
        static let name = "detail.name"
        static let weight = "detail.weight"
        static let price = "detail.price"
        static let description = "detail.description"
        static let addButton = "detail.addButton"
        static let stepperDecrement = "detail.stepper.decrement"
        static let stepperCount = "detail.stepper.count"
        static let stepperIncrement = "detail.stepper.increment"
    }
    enum Cart {
        static let empty = "cart.empty"
        static let checkout = "cart.checkout"
        static func item(_ productId: String) -> String { "cart.item.\(productId)" }
        static func stepperDecrement(_ productId: String) -> String { "cart.item.\(productId).stepper.decrement" }
        static func stepperCount(_ productId: String) -> String { "cart.item.\(productId).stepper.count" }
        static func stepperIncrement(_ productId: String) -> String { "cart.item.\(productId).stepper.increment" }
    }
    enum Checkout {
        static let address = "checkout.address"
        static let confirm = "checkout.confirm"
        static let geocodeError = "checkout.geocodeError"
    }
    enum Orders {
        static let empty = "orders.empty"
        static func cell(_ orderId: String) -> String { "orders.cell.\(orderId)" }
    }
    enum Promotions {
        static func cell(_ id: String) -> String { "promotions.cell.\(id)" }
    }
    enum Profile {
        static let name = "profile.name"
        static let phone = "profile.phone"
        static let email = "profile.email"
        static let logout = "profile.logout"
    }
}
