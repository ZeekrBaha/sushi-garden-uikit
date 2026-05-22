import XCTest

final class CatalogUITests: XCTestCase {
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

    func test_catalogLoads_withAllCategoryTabs() {
        XCTAssertTrue(app.cells[AX.Catalog.category("rolls")].waitForExistence(timeout: 3))
        XCTAssertTrue(app.cells[AX.Catalog.category("sushi")].exists)
        XCTAssertTrue(app.cells[AX.Catalog.category("hot_rolls")].exists)
        XCTAssertTrue(app.cells[AX.Catalog.category("salads")].exists)
        XCTAssertTrue(app.cells[AX.Catalog.category("wok")].exists)
    }

    func test_selectRolls_showsProducts() {
        app.cells[AX.Catalog.category("rolls")].tap()
        XCTAssertTrue(app.cells[AX.Catalog.product("hikari")].waitForExistence(timeout: 2))
    }

    func test_productCard_showsNameWeightPrice() {
        app.cells[AX.Catalog.category("rolls")].tap()
        XCTAssertTrue(app.cells[AX.Catalog.product("hikari")].waitForExistence(timeout: 2))
        let card = app.cells[AX.Catalog.product("hikari")]
        XCTAssertTrue(card.staticTexts["Хикари"].exists)
        XCTAssertTrue(card.staticTexts["255 г"].exists)
        XCTAssertTrue(card.staticTexts["620 ₽"].exists)
    }

    func test_addButton_addsProductToCart() {
        app.cells[AX.Catalog.category("rolls")].tap()
        XCTAssertTrue(app.buttons[AX.Catalog.addButton("hikari")].waitForExistence(timeout: 2))
        app.buttons[AX.Catalog.addButton("hikari")].tap()
        app.navigateToCart()
        XCTAssertFalse(app.staticTexts[AX.Cart.empty].exists)
        XCTAssertTrue(app.cells[AX.Cart.item("hikari")].waitForExistence(timeout: 2))
    }

    func test_tappingProduct_opensProductDetail() {
        app.cells[AX.Catalog.category("rolls")].tap()
        XCTAssertTrue(app.cells[AX.Catalog.product("hikari")].waitForExistence(timeout: 2))
        app.cells[AX.Catalog.product("hikari")].tap()
        XCTAssertTrue(app.staticTexts[AX.Detail.name].waitForExistence(timeout: 2))
    }

    func test_backFromDetail_returnsToCatalog() {
        app.cells[AX.Catalog.category("rolls")].tap()
        XCTAssertTrue(app.cells[AX.Catalog.product("hikari")].waitForExistence(timeout: 2))
        app.cells[AX.Catalog.product("hikari")].tap()
        XCTAssertTrue(app.staticTexts[AX.Detail.name].waitForExistence(timeout: 2))
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.cells[AX.Catalog.product("hikari")].waitForExistence(timeout: 2))
    }
}
