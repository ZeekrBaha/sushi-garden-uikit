import XCTest

final class CheckoutUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication.makeAuthenticated()
        app.launch()
        app.waitForCatalog()
        // Navigate to checkout with one item
        app.addRollToCart()
        app.navigateToCart()
        XCTAssertTrue(app.buttons[AX.Cart.checkout].waitForExistence(timeout: 3))
        app.buttons[AX.Cart.checkout].tap()
        XCTAssertTrue(app.buttons[AX.Checkout.confirm].waitForExistence(timeout: 3))
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    func test_checkoutScreen_showsRequiredElements() {
        XCTAssertTrue(app.staticTexts[AX.Checkout.address].exists)
        XCTAssertTrue(app.buttons[AX.Checkout.confirm].exists)
    }

    func test_confirmButton_startsDisabled() {
        XCTAssertFalse(app.buttons[AX.Checkout.confirm].isEnabled)
    }

    func test_addressLabel_exists() {
        XCTAssertTrue(app.staticTexts[AX.Checkout.address].exists)
    }

    func test_geocodeErrorLabel_hiddenInitially() {
        // The error label should be hidden unless geocoding fails
        let errorLabel = app.staticTexts[AX.Checkout.geocodeError]
        // Either doesn't exist or is not hittable (hidden)
        XCTAssertFalse(errorLabel.isHittable)
    }
}
