import XCTest
@testable import SushiGarden

final class FieldValidatorsTests: XCTestCase {
    func test_email_validAndInvalid() {
        XCTAssertTrue(FieldValidators.isValidEmail("user@example.com"))
        XCTAssertFalse(FieldValidators.isValidEmail("user@"))
        XCTAssertFalse(FieldValidators.isValidEmail("nope"))
        XCTAssertFalse(FieldValidators.isValidEmail(""))
    }

    func test_password_requiresMinimumSixCharacters() {
        XCTAssertTrue(FieldValidators.isValidPassword("secret1"))
        XCTAssertFalse(FieldValidators.isValidPassword("12345"))
    }

    func test_phone_requiresAtLeastTenDigits() {
        XCTAssertTrue(FieldValidators.isValidPhone("+7 999 123 45 67"))
        XCTAssertFalse(FieldValidators.isValidPhone("12345"))
    }

    func test_nonEmpty_trimsWhitespace() {
        XCTAssertTrue(FieldValidators.isNonEmpty("  Баха  "))
        XCTAssertFalse(FieldValidators.isNonEmpty("   "))
    }
}
