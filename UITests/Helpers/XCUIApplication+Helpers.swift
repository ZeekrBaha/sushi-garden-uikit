import XCTest

extension XCUIApplication {
    static func makeUnauthenticated() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        return app
    }

    static func makeAuthenticated() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--uitesting-authenticated"]
        return app
    }

    func waitForLoginScreen(timeout: TimeInterval = 5) {
        XCTAssertTrue(buttons[AX.Login.loginButton].waitForExistence(timeout: timeout),
                      "Login screen did not appear within \(timeout)s")
    }

    func waitForCatalog(timeout: TimeInterval = 5) {
        XCTAssertTrue(tabBars.firstMatch.waitForExistence(timeout: timeout),
                      "Catalog tab bar did not appear within \(timeout)s")
    }

    func loginWithSeededCredentials() {
        waitForLoginScreen()
        let emailField = textFields[AX.Login.email]
        emailField.tap()
        emailField.typeText("test@sushi.ru")
        let passwordField = secureTextFields[AX.Login.password]
        passwordField.tap()
        passwordField.typeText("secret1")
        buttons[AX.Login.loginButton].tap()
        waitForCatalog()
    }

    func addRollToCart(productId: String = "hikari") {
        XCTAssertTrue(cells[AX.Catalog.category("rolls")].waitForExistence(timeout: 3))
        cells[AX.Catalog.category("rolls")].tap()
        XCTAssertTrue(buttons[AX.Catalog.addButton(productId)].waitForExistence(timeout: 3))
        buttons[AX.Catalog.addButton(productId)].tap()
    }

    func navigateToCart() {
        tabBars.buttons["Корзина"].tap()
    }

    func navigateToTab(_ title: String) {
        tabBars.buttons[title].tap()
    }
}
