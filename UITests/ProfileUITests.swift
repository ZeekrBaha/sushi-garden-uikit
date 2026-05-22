import XCTest

final class ProfileUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication.makeAuthenticated()
        app.launch()
        app.waitForCatalog()
        app.navigateToTab("Профиль")
        XCTAssertTrue(app.buttons[AX.Profile.logout].waitForExistence(timeout: 3))
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    func test_profileScreen_showsSeededUserName() {
        XCTAssertTrue(app.staticTexts[AX.Profile.name].exists)
        XCTAssertEqual(app.staticTexts[AX.Profile.name].label, "Тест")
    }

    func test_profileScreen_showsPhone() {
        XCTAssertTrue(app.staticTexts[AX.Profile.phone].exists)
        XCTAssertEqual(app.staticTexts[AX.Profile.phone].label, "+79990000000")
    }

    func test_profileScreen_showsEmail() {
        XCTAssertTrue(app.staticTexts[AX.Profile.email].exists)
        XCTAssertEqual(app.staticTexts[AX.Profile.email].label, "test@sushi.ru")
    }

    func test_logout_navigatesToLoginScreen() {
        app.buttons[AX.Profile.logout].tap()
        XCTAssertTrue(app.buttons[AX.Login.loginButton].waitForExistence(timeout: 3))
    }

    func test_logout_thenLoginAgain_succeeds() {
        app.buttons[AX.Profile.logout].tap()
        app.loginWithSeededCredentials()
        XCTAssertTrue(app.tabBars.firstMatch.exists)
    }

    func test_logout_repeatedLoginLogout_noAccumulation() {
        // Exercises the AppCoordinator child-coordinator retention bug fix
        app.buttons[AX.Profile.logout].tap()
        app.loginWithSeededCredentials()
        app.navigateToTab("Профиль")
        XCTAssertTrue(app.buttons[AX.Profile.logout].waitForExistence(timeout: 3))
        app.buttons[AX.Profile.logout].tap()
        XCTAssertTrue(app.buttons[AX.Login.loginButton].waitForExistence(timeout: 3))
    }
}
