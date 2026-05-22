import Foundation

enum FieldValidators {
    static func isValidEmail(_ value: String) -> Bool {
        let pattern = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        return value.range(of: pattern, options: .regularExpression) != nil
    }

    static func isValidPassword(_ value: String) -> Bool {
        value.count >= 6
    }

    static func isValidPhone(_ value: String) -> Bool {
        value.filter(\.isNumber).count >= 10
    }

    static func isNonEmpty(_ value: String) -> Bool {
        !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
