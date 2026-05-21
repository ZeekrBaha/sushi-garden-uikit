import Foundation
import CoreLocation
import Combine

// Protocol allows injecting a synchronous mock in tests instead of CLGeocoder.
protocol Geocoding {
    func reverseGeocodeLocation(_ location: CLLocation,
                                completionHandler: @escaping ([CLPlacemark]?, Error?) -> Void)
    func cancelGeocode()
}

extension CLGeocoder: Geocoding {}

final class CheckoutViewModel {
    let items: [CartItem]
    let totalPrice: Int

    @Published private(set) var address: String = ""
    @Published private(set) var geocodingFailed: Bool = false
    private(set) var lastDeliveryAddress: DeliveryAddress?
    var canPlaceOrder: Bool { lastDeliveryAddress != nil }

    var onOrderPlaced: (() -> Void)?

    private let orders: OrdersServicing
    private let cart: CartServicing
    private let geocoder: Geocoding

    init(items: [CartItem], totalPrice: Int,
         orders: OrdersServicing, cart: CartServicing,
         geocoder: Geocoding = CLGeocoder()) {
        self.items = items
        self.totalPrice = totalPrice
        self.orders = orders
        self.cart = cart
        self.geocoder = geocoder
    }

    func reverseGeocode(location: CLLocation) {
        geocoder.cancelGeocode()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self else { return }
            guard error == nil, let placemark = placemarks?.first else {
                self.geocodingFailed = true
                return
            }
            let delivery = DeliveryAddress(
                city: placemark.locality ?? "",
                street: placemark.thoroughfare ?? "",
                building: placemark.subThoroughfare ?? ""
            )
            self.lastDeliveryAddress = delivery
            self.address = delivery.formatted
            self.geocodingFailed = false
        }
    }

    func placeOrder() {
        guard let delivery = lastDeliveryAddress else { return }
        _ = orders.placeOrder(items: items, address: delivery)
        cart.clear()
        onOrderPlaced?()
    }
}
