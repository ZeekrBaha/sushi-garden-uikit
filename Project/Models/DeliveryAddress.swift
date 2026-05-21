struct DeliveryAddress: Equatable, Hashable {
    let city: String
    let street: String
    let building: String

    var formatted: String { "\(city), \(street) \(building)" }
}
