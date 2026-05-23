import XCTest

final class AuthUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication.makeUnauthenticated()
        app.launch()
        app.waitForLoginScreen()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: - Splash → Login

    func test_splashSkippedAndLoginShows() {
        XCTAssertTrue(app.buttons[AX.Login.loginButton].exists)
    }

    // MARK: - Login screen elements

    func test_loginScreen_hasRequiredElements() {
        XCTAssertTrue(app.textFields[AX.Login.email].exists)
        XCTAssertTrue(app.secureTextFields[AX.Login.password].exists)
        XCTAssertTrue(app.buttons[AX.Login.loginButton].exists)
        XCTAssertTrue(app.buttons[AX.Login.registerLink].exists)
    }

    // MARK: - Login validation

    func test_emptyLogin_doesNotProceed() {
        app.buttons[AX.Login.loginButton].tap()
        XCTAssertFalse(app.tabBars.firstMatch.exists)
    }

    func test_invalidEmail_doesNotProceed() {
        app.textFields[AX.Login.email].tap()
        app.textFields[AX.Login.email].typeText("notanemail")
        app.secureTextFields[AX.Login.password].tap()
        app.secureTextFields[AX.Login.password].typeText("secret1")
        app.buttons[AX.Login.loginButton].tap()
        XCTAssertFalse(app.tabBars.firstMatch.exists)
    }

    func test_wrongPassword_showsAuthError() {
        app.textFields[AX.Login.email].tap()
        app.textFields[AX.Login.email].typeText("test@sushi.ru")
        app.secureTextFields[AX.Login.password].tap()
        app.secureTextFields[AX.Login.password].typeText("wrongpassword")
        app.buttons[AX.Login.loginButton].tap()
        XCTAssertTrue(app.staticTexts[AX.Login.authError].waitForExistence(timeout: 2))
    }

    func test_validLogin_opensCatalog() {
        app.textFields[AX.Login.email].tap()
        app.textFields[AX.Login.email].typeText("test@sushi.ru")
        app.secureTextFields[AX.Login.password].tap()
        app.secureTextFields[AX.Login.password].typeText("secret1")
        app.buttons[AX.Login.loginButton].tap()
        app.waitForCatalog()
        XCTAssertTrue(app.tabBars.firstMatch.exists)
    }

    // MARK: - Login ↔ Register toggle

    func test_tapRegisterLink_opensRegisterScreen() {
        app.buttons[AX.Login.registerLink].tap()
        XCTAssertTrue(app.buttons[AX.Register.registerButton].waitForExistence(timeout: 2))
    }

    func test_tapLoginLink_returnsToLogin() {
        app.buttons[AX.Login.registerLink].tap()
        XCTAssertTrue(app.buttons[AX.Register.loginLink].waitForExistence(timeout: 2))
        app.buttons[AX.Register.loginLink].tap()
        XCTAssertTrue(app.buttons[AX.Login.loginButton].waitForExistence(timeout: 2))
    }

    // MARK: - Register screen elements

    func test_registerScreen_hasRequiredElements() {
        app.buttons[AX.Login.registerLink].tap()
        XCTAssertTrue(app.textFields[AX.Register.name].waitForExistence(timeout: 2))
        XCTAssertTrue(app.textFields[AX.Register.email].exists)
        XCTAssertTrue(app.secureTextFields[AX.Register.password].exists)
        XCTAssertTrue(app.otherElements[AX.Register.consent].exists)
        XCTAssertTrue(app.buttons[AX.Register.registerButton].exists)
        XCTAssertTrue(app.buttons[AX.Register.loginLink].exists)
    }

    // MARK: - Register validation

    func test_emptyRegister_doesNotProceed() {
        app.buttons[AX.Login.registerLink].tap()
        XCTAssertTrue(app.buttons[AX.Register.registerButton].waitForExistence(timeout: 2))
        app.buttons[AX.Register.registerButton].tap()
        XCTAssertFalse(app.tabBars.firstMatch.exists)
    }

    func test_duplicateEmail_showsAuthError() {
        app.buttons[AX.Login.registerLink].tap()
        XCTAssertTrue(app.textFields[AX.Register.name].waitForExistence(timeout: 2))
        app.textFields[AX.Register.name].tap()
        app.textFields[AX.Register.name].typeText("Test User")
        app.textFields[AX.Register.email].tap()
        app.textFields[AX.Register.email].typeText("test@sushi.ru")
        app.secureTextFields[AX.Register.password].tap()
        app.secureTextFields[AX.Register.password].typeText("password123")
        app.otherElements[AX.Register.consent].tap()
        app.buttons[AX.Register.registerButton].tap()
        XCTAssertTrue(app.staticTexts[AX.Register.authError].waitForExistence(timeout: 2))
    }

    func test_validRegistration_opensCatalog() {
        app.buttons[AX.Login.registerLink].tap()
        XCTAssertTrue(app.textFields[AX.Register.name].waitForExistence(timeout: 2))
        app.textFields[AX.Register.name].tap()
        app.textFields[AX.Register.name].typeText("Новый Пользователь")
        app.textFields[AX.Register.email].tap()
        app.textFields[AX.Register.email].typeText("newuser@uitest.ru")
        app.secureTextFields[AX.Register.password].tap()
        app.secureTextFields[AX.Register.password].typeText("password123")
        app.otherElements[AX.Register.consent].tap()
        app.buttons[AX.Register.registerButton].tap()
        app.waitForCatalog()
        XCTAssertTrue(app.tabBars.firstMatch.exists)
    }
}
