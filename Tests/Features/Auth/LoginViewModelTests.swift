import XCTest
@testable import SushiGarden

final class LoginViewModelTests: XCTestCase {
    func test_login_withInvalidEmail_setsEmailError() {
        let sut = LoginViewModel(auth: InMemoryAuthService())
        sut.login(email: "notanemail", password: "secret1")
        XCTAssertNotNil(sut.emailError)
        XCTAssertNil(sut.passwordError)
        XCTAssertNil(sut.authError)
    }

    func test_login_withShortPassword_setsPasswordError() {
        let sut = LoginViewModel(auth: InMemoryAuthService())
        sut.login(email: "test@sushi.ru", password: "abc")
        XCTAssertNil(sut.emailError)
        XCTAssertNotNil(sut.passwordError)
    }

    func test_login_withBothFieldsInvalid_setsBothErrors() {
        let sut = LoginViewModel(auth: InMemoryAuthService())
        sut.login(email: "bad", password: "x")
        XCTAssertNotNil(sut.emailError)
        XCTAssertNotNil(sut.passwordError)
    }

    func test_login_withValidCredentials_callsOnLoginSuccess() {
        let sut = LoginViewModel(auth: InMemoryAuthService())
        var didCallSuccess = false
        sut.onLoginSuccess = { didCallSuccess = true }
        sut.login(email: "test@sushi.ru", password: "secret1")
        XCTAssertTrue(didCallSuccess)
        XCTAssertNil(sut.authError)
    }

    func test_login_withWrongPassword_setsAuthError() {
        let sut = LoginViewModel(auth: InMemoryAuthService())
        sut.login(email: "test@sushi.ru", password: "wrongpassword")
        XCTAssertNotNil(sut.authError)
        XCTAssertNil(sut.emailError)
        XCTAssertNil(sut.passwordError)
    }

    func test_login_clearsErrorsOnRetry() {
        let sut = LoginViewModel(auth: InMemoryAuthService())
        sut.login(email: "bad", password: "x")
        sut.login(email: "test@sushi.ru", password: "secret1")
        XCTAssertNil(sut.emailError)
        XCTAssertNil(sut.passwordError)
    }

    func test_goToRegister_callsOnGoToRegister() {
        let sut = LoginViewModel(auth: InMemoryAuthService())
        var called = false
        sut.onGoToRegister = { called = true }
        sut.goToRegister()
        XCTAssertTrue(called)
    }
}
