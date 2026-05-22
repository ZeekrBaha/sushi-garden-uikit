import Foundation

final class LoginViewModel {
    private(set) var emailError: String?
    private(set) var passwordError: String?
    private(set) var authError: String?

    var onLoginSuccess: (() -> Void)?
    var onGoToRegister: (() -> Void)?

    private let auth: AuthServicing

    init(auth: AuthServicing) {
        self.auth = auth
    }

    func login(email: String, password: String) {
        emailError = nil
        passwordError = nil
        authError = nil

        var valid = true
        if !FieldValidators.isValidEmail(email) {
            emailError = "Введите корректный email"
            valid = false
        }
        if !FieldValidators.isValidPassword(password) {
            passwordError = "Пароль — минимум 6 символов"
            valid = false
        }
        guard valid else { return }

        switch auth.login(email: email, password: password) {
        case .success:
            onLoginSuccess?()
        case .failure:
            authError = "Неверный email или пароль"
        }
    }

    func goToRegister() {
        onGoToRegister?()
    }
}
