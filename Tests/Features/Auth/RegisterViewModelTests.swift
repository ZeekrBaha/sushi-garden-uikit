import XCTest
@testable import SushiGarden

final class RegisterViewModelTests: XCTestCase {
    func test_register_withEmptyName_setsNameError() {
        let sut = RegisterViewModel(auth: InMemoryAuthService())
        sut.register(name: "  ", phone: "+79991234567", email: "new@sushi.ru", password: "secret1")
        XCTAssertNotNil(sut.nameError)
        XCTAssertNil(sut.phoneError)
        XCTAssertNil(sut.emailError)
        XCTAssertNil(sut.passwordError)
    }

    func test_register_withInvalidPhone_setsPhoneError() {
        let sut = RegisterViewModel(auth: InMemoryAuthService())
        sut.register(name: "Баха", phone: "123", email: "new@sushi.ru", password: "secret1")
        XCTAssertNil(sut.nameError)
        XCTAssertNotNil(sut.phoneError)
    }

    func test_register_withInvalidEmail_setsEmailError() {
        let sut = RegisterViewModel(auth: InMemoryAuthService())
        sut.register(name: "Баха", phone: "+79991234567", email: "bad", password: "secret1")
        XCTAssertNil(sut.nameError)
        XCTAssertNil(sut.phoneError)
        XCTAssertNotNil(sut.emailError)
    }

    func test_register_withShortPassword_setsPasswordError() {
        let sut = RegisterViewModel(auth: InMemoryAuthService())
        sut.register(name: "Баха", phone: "+79991234567", email: "new@sushi.ru", password: "abc")
        XCTAssertNotNil(sut.passwordError)
    }

    func test_register_withValidData_callsOnRegisterSuccess() {
        let sut = RegisterViewModel(auth: InMemoryAuthService())
        var didCallSuccess = false
        sut.onRegisterSuccess = { didCallSuccess = true }
        sut.register(name: "Баха", phone: "+79991234567", email: "new@sushi.ru", password: "secret1")
        XCTAssertTrue(didCallSuccess)
        XCTAssertNil(sut.authError)
    }

    func test_register_withDuplicateEmail_setsAuthError() {
        let sut = RegisterViewModel(auth: InMemoryAuthService())
        // test@sushi.ru is the seeded account
        sut.register(name: "Кто-то", phone: "+79991234567", email: "test@sushi.ru", password: "secret1")
        XCTAssertNotNil(sut.authError)
    }

    func test_register_clearsErrorsOnRetry() {
        let sut = RegisterViewModel(auth: InMemoryAuthService())
        sut.register(name: "", phone: "x", email: "bad", password: "x")
        sut.register(name: "Баха", phone: "+79991234567", email: "new@sushi.ru", password: "secret1")
        XCTAssertNil(sut.nameError)
        XCTAssertNil(sut.phoneError)
        XCTAssertNil(sut.emailError)
        XCTAssertNil(sut.passwordError)
    }

    func test_goToLogin_callsOnGoToLogin() {
        let sut = RegisterViewModel(auth: InMemoryAuthService())
        var called = false
        sut.onGoToLogin = { called = true }
        sut.goToLogin()
        XCTAssertTrue(called)
    }
}
