import XCTest
@testable import SushiGarden

final class FormFieldTests: XCTestCase {
    func test_errorMessage_setAndGet() {
        let sut = FormField(placeholder: "Email")
        sut.errorMessage = "Введите email"
        XCTAssertEqual(sut.errorMessage, "Введите email")
    }

    func test_nilErrorMessage_clearsError() {
        let sut = FormField(placeholder: "Email")
        sut.errorMessage = "Error"
        sut.errorMessage = nil
        XCTAssertNil(sut.errorMessage)
    }

    func test_textField_isConfigured() {
        let sut = FormField(placeholder: "Email")
        XCTAssertEqual(sut.textField.autocapitalizationType, .none)
        XCTAssertFalse(sut.textField.isSecureTextEntry)
    }

    func test_secureField_isSecure() {
        let sut = FormField(placeholder: "Пароль", isSecure: true)
        XCTAssertTrue(sut.textField.isSecureTextEntry)
    }
}
