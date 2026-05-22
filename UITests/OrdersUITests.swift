import XCTest

final class OrdersUITests: XCTestCase {
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

    func test_emptyOrders_showsEmptyState() {
        app.navigateToTab("Заказы")
        XCTAssertTrue(app.staticTexts[AX.Orders.empty].waitForExistence(timeout: 2))
    }

    func test_ordersTab_isAccessible() {
        app.navigateToTab("Заказы")
        XCTAssertFalse(app.tabBars.buttons["Заказы"].isSelected == false &&
                       !app.staticTexts[AX.Orders.empty].waitForExistence(timeout: 2))
    }
}
