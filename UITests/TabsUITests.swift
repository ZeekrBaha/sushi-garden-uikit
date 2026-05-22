import XCTest

final class TabsUITests: XCTestCase {
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

    func test_allFiveTabsExist() {
        XCTAssertTrue(app.tabBars.buttons["Каталог"].exists)
        XCTAssertTrue(app.tabBars.buttons["Заказы"].exists)
        XCTAssertTrue(app.tabBars.buttons["Акции"].exists)
        XCTAssertTrue(app.tabBars.buttons["Корзина"].exists)
        XCTAssertTrue(app.tabBars.buttons["Профиль"].exists)
    }

    func test_ordersTab_opensOrdersScreen() {
        app.navigateToTab("Заказы")
        XCTAssertTrue(app.staticTexts[AX.Orders.empty].waitForExistence(timeout: 2))
    }

    func test_promotionsTab_opensPromotionsScreen() {
        app.navigateToTab("Акции")
        XCTAssertTrue(app.cells[AX.Promotions.cell("1")].waitForExistence(timeout: 2))
    }

    func test_cartTab_opensCartScreen() {
        app.navigateToTab("Корзина")
        XCTAssertTrue(app.staticTexts[AX.Cart.empty].waitForExistence(timeout: 2))
    }

    func test_profileTab_opensProfileScreen() {
        app.navigateToTab("Профиль")
        XCTAssertTrue(app.buttons[AX.Profile.logout].waitForExistence(timeout: 2))
    }

    func test_addItem_cartIsNoLongerEmpty() {
        app.addRollToCart()
        app.navigateToCart()
        XCTAssertFalse(app.staticTexts[AX.Cart.empty].exists)
    }
}
