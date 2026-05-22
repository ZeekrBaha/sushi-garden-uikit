import XCTest

final class ProductDetailUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication.makeAuthenticated()
        app.launch()
        app.waitForCatalog()
        app.cells[AX.Catalog.category("rolls")].tap()
        XCTAssertTrue(app.cells[AX.Catalog.product("hikari")].waitForExistence(timeout: 3))
        app.cells[AX.Catalog.product("hikari")].tap()
        XCTAssertTrue(app.staticTexts[AX.Detail.name].waitForExistence(timeout: 3))
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    func test_detailScreen_showsProductInfo() {
        XCTAssertTrue(app.staticTexts[AX.Detail.name].exists)
        XCTAssertTrue(app.staticTexts[AX.Detail.weight].exists)
        XCTAssertTrue(app.staticTexts[AX.Detail.price].exists)
    }

    func test_detailScreen_showsCorrectValues() {
        XCTAssertEqual(app.staticTexts[AX.Detail.name].label, "Хикари")
        XCTAssertEqual(app.staticTexts[AX.Detail.weight].label, "255 г")
        XCTAssertEqual(app.staticTexts[AX.Detail.price].label, "620 ₽")
    }

    func test_stepper_startsAtOne() {
        XCTAssertEqual(app.staticTexts[AX.Detail.stepperCount].label, "1")
    }

    func test_stepper_increments() {
        app.buttons[AX.Detail.stepperIncrement].tap()
        XCTAssertEqual(app.staticTexts[AX.Detail.stepperCount].label, "2")
    }

    func test_stepper_decrementsAfterIncrement() {
        app.buttons[AX.Detail.stepperIncrement].tap()
        app.buttons[AX.Detail.stepperDecrement].tap()
        XCTAssertEqual(app.staticTexts[AX.Detail.stepperCount].label, "1")
    }

    func test_stepper_doesNotGoBelowOne() {
        app.buttons[AX.Detail.stepperDecrement].tap()
        XCTAssertEqual(app.staticTexts[AX.Detail.stepperCount].label, "1")
    }

    func test_addButton_addsItemToCart() {
        app.buttons[AX.Detail.stepperIncrement].tap()
        app.buttons[AX.Detail.stepperIncrement].tap()
        XCTAssertEqual(app.staticTexts[AX.Detail.stepperCount].label, "3")
        app.buttons[AX.Detail.addButton].tap()
        app.navigateToCart()
        XCTAssertFalse(app.staticTexts[AX.Cart.empty].exists)
    }
}
