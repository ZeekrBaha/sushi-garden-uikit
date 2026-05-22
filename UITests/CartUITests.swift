import XCTest

final class CartUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication.makeAuthenticated()
        app.launch()
        app.waitForCatalog()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: - Empty state

    func test_emptyCart_showsEmptyState() {
        app.navigateToCart()
        XCTAssertTrue(app.staticTexts[AX.Cart.empty].waitForExistence(timeout: 2))
    }

    func test_emptyCart_hidesCheckoutButton() {
        app.navigateToCart()
        XCTAssertFalse(app.buttons[AX.Cart.checkout].exists)
    }

    // MARK: - Cart with items

    func test_cartWithItem_showsItemRow() {
        app.addRollToCart()
        app.navigateToCart()
        XCTAssertTrue(app.cells[AX.Cart.item("hikari")].waitForExistence(timeout: 2))
    }

    func test_cartWithItem_showsCheckoutButton() {
        app.addRollToCart()
        app.navigateToCart()
        XCTAssertTrue(app.buttons[AX.Cart.checkout].waitForExistence(timeout: 2))
    }

    func test_cartWithItem_hidesEmptyState() {
        app.addRollToCart()
        app.navigateToCart()
        XCTAssertFalse(app.staticTexts[AX.Cart.empty].exists)
    }

    // MARK: - Quantity stepper

    func test_incrementQuantity_updatesSubtotal() {
        app.addRollToCart()
        app.navigateToCart()
        XCTAssertTrue(app.cells[AX.Cart.item("hikari")].waitForExistence(timeout: 2))
        app.buttons[AX.Cart.stepperIncrement("hikari")].tap()
        // Hikari is 620 ₽; 2 × 620 = 1240 ₽
        XCTAssertTrue(app.cells[AX.Cart.item("hikari")].staticTexts["1240 ₽"].exists)
    }

    func test_decrementToOne_doesNotRemoveItem() {
        app.addRollToCart()
        app.navigateToCart()
        XCTAssertTrue(app.cells[AX.Cart.item("hikari")].waitForExistence(timeout: 2))
        app.buttons[AX.Cart.stepperDecrement("hikari")].tap()
        XCTAssertTrue(app.cells[AX.Cart.item("hikari")].exists,
                      "Item should still be in cart at quantity 1")
    }

    // MARK: - Swipe to delete

    func test_swipeDelete_removesItem() {
        app.addRollToCart()
        app.navigateToCart()
        XCTAssertTrue(app.cells[AX.Cart.item("hikari")].waitForExistence(timeout: 2))
        app.cells[AX.Cart.item("hikari")].swipeLeft()
        app.buttons["Удалить"].tap()
        XCTAssertTrue(app.staticTexts[AX.Cart.empty].waitForExistence(timeout: 2))
    }

    // MARK: - Checkout navigation

    func test_checkoutButton_opensCheckoutScreen() {
        app.addRollToCart()
        app.navigateToCart()
        XCTAssertTrue(app.buttons[AX.Cart.checkout].waitForExistence(timeout: 2))
        app.buttons[AX.Cart.checkout].tap()
        XCTAssertTrue(app.buttons[AX.Checkout.confirm].waitForExistence(timeout: 3))
    }
}
