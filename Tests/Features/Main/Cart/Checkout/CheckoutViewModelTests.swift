import XCTest
import CoreLocation
import MapKit
@testable import SushiGarden

final class CheckoutViewModelTests: XCTestCase {

    // MARK: - Helpers

    private final class MockGeocoder: Geocoding {
        var stubbedPlacemarks: [CLPlacemark]?
        var stubbedError: Error?
        private(set) var cancelCalled = false

        func reverseGeocodeLocation(_ location: CLLocation,
                                    completionHandler: @escaping ([CLPlacemark]?, Error?) -> Void) {
            completionHandler(stubbedPlacemarks, stubbedError)
        }

        func cancelGeocode() { cancelCalled = true }
    }

    private func makeProduct() -> Product {
        Product(id: "p1", name: "Тест", categoryId: "rolls",
                weightGrams: 200, price: 500, imageName: "", description: "")
    }

    private func makeSUT(
        cart: CartServicing = InMemoryCartService(),
        orders: OrdersServicing = InMemoryOrdersService(),
        geocoder: Geocoding = MockGeocoder()
    ) -> CheckoutViewModel {
        let items = [CartItem(product: makeProduct(), quantity: 2)]
        return CheckoutViewModel(items: items, totalPrice: 1000,
                                 orders: orders, cart: cart, geocoder: geocoder)
    }

    private func successGeocoder() -> MockGeocoder {
        let mock = MockGeocoder()
        mock.stubbedPlacemarks = [MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 55.7, longitude: 37.6))]
        return mock
    }

    private let testLocation = CLLocation(latitude: 55.7558, longitude: 37.6173)

    // MARK: - Tests

    func test_address_initiallyEmpty() {
        XCTAssertTrue(makeSUT().address.isEmpty)
    }

    func test_canPlaceOrder_falseWhenNoAddress() {
        XCTAssertFalse(makeSUT().canPlaceOrder)
    }

    func test_reverseGeocode_onSuccess_setsLastDeliveryAddress() {
        let sut = makeSUT(geocoder: successGeocoder())
        sut.reverseGeocode(location: testLocation)
        XCTAssertNotNil(sut.lastDeliveryAddress)
    }

    func test_reverseGeocode_onSuccess_clearsGeocodingFailed() {
        let mock = MockGeocoder()
        mock.stubbedError = NSError(domain: "test", code: 1)
        let sut = makeSUT(geocoder: mock)
        sut.reverseGeocode(location: testLocation) // first call fails

        let successMock = successGeocoder()
        let sut2 = makeSUT(geocoder: successMock)
        sut2.reverseGeocode(location: testLocation)
        XCTAssertFalse(sut2.geocodingFailed)
    }

    func test_reverseGeocode_onError_setsGeocodingFailed() {
        let mock = MockGeocoder()
        mock.stubbedError = NSError(domain: "test", code: 1)
        let sut = makeSUT(geocoder: mock)
        sut.reverseGeocode(location: testLocation)
        XCTAssertTrue(sut.geocodingFailed)
        XCTAssertNil(sut.lastDeliveryAddress)
    }

    func test_reverseGeocode_onEmptyPlacemarks_setsGeocodingFailed() {
        let mock = MockGeocoder()
        mock.stubbedPlacemarks = []
        let sut = makeSUT(geocoder: mock)
        sut.reverseGeocode(location: testLocation)
        XCTAssertTrue(sut.geocodingFailed)
    }

    func test_reverseGeocode_cancelsPreviousRequest() {
        let mock = successGeocoder()
        let sut = makeSUT(geocoder: mock)
        sut.reverseGeocode(location: testLocation)
        XCTAssertTrue(mock.cancelCalled)
    }

    func test_canPlaceOrder_trueAfterSuccessfulGeocode() {
        let sut = makeSUT(geocoder: successGeocoder())
        sut.reverseGeocode(location: testLocation)
        XCTAssertTrue(sut.canPlaceOrder)
    }

    func test_placeOrder_callsOrdersService() {
        let orders = InMemoryOrdersService()
        let sut = makeSUT(orders: orders, geocoder: successGeocoder())
        sut.reverseGeocode(location: testLocation)
        sut.placeOrder()
        XCTAssertEqual(orders.orders.count, 1)
    }

    func test_placeOrder_ordersServiceReceivesCorrectItems() {
        let orders = InMemoryOrdersService()
        let sut = makeSUT(orders: orders, geocoder: successGeocoder())
        sut.reverseGeocode(location: testLocation)
        sut.placeOrder()
        XCTAssertEqual(orders.orders.first?.items.first?.product.id, "p1")
    }

    func test_placeOrder_clearsCart() {
        let cart = InMemoryCartService()
        cart.add(makeProduct())
        let sut = makeSUT(cart: cart, geocoder: successGeocoder())
        sut.reverseGeocode(location: testLocation)
        sut.placeOrder()
        XCTAssertTrue(cart.items.isEmpty)
    }

    func test_placeOrder_firesOnOrderPlaced() {
        let sut = makeSUT(geocoder: successGeocoder())
        var called = false
        sut.onOrderPlaced = { called = true }
        sut.reverseGeocode(location: testLocation)
        sut.placeOrder()
        XCTAssertTrue(called)
    }

    func test_placeOrder_whenNoAddress_doesNothing() {
        let orders = InMemoryOrdersService()
        let sut = makeSUT(orders: orders)
        sut.placeOrder()
        XCTAssertEqual(orders.orders.count, 0)
    }
}
