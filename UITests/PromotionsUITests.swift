import XCTest

final class PromotionsUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication.makeAuthenticated()
        app.launch()
        app.waitForCatalog()
        app.navigateToTab("Акции")
        XCTAssertTrue(app.cells[AX.Promotions.cell("1")].waitForExistence(timeout: 3))
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    func test_promotionsTab_showsAllFourCards() {
        XCTAssertTrue(app.cells[AX.Promotions.cell("1")].exists)
        XCTAssertTrue(app.cells[AX.Promotions.cell("2")].exists)
        XCTAssertTrue(app.cells[AX.Promotions.cell("3")].exists)
        XCTAssertTrue(app.cells[AX.Promotions.cell("4")].exists)
    }

    func test_firstPromotion_showsTitleAndDescription() {
        let card = app.cells[AX.Promotions.cell("1")]
        XCTAssertTrue(card.staticTexts["Бесплатная доставка"].exists)
        XCTAssertTrue(card.staticTexts["При заказе от 1500 ₽"].exists)
    }

    func test_secondPromotion_showsTitleAndDescription() {
        let card = app.cells[AX.Promotions.cell("2")]
        XCTAssertTrue(card.staticTexts["Ролл в подарок"].exists)
    }

    func test_thirdPromotion_showsTitleAndDescription() {
        let card = app.cells[AX.Promotions.cell("3")]
        XCTAssertTrue(card.staticTexts["Скидка 10%"].exists)
    }

    func test_fourthPromotion_showsTitleAndDescription() {
        let card = app.cells[AX.Promotions.cell("4")]
        XCTAssertTrue(card.staticTexts["Комбо-обед"].exists)
    }
}
