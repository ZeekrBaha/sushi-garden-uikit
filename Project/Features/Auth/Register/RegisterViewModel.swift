import Foundation

final class RegisterViewModel {
    private(set) var nameError: String?
    private(set) var emailError: String?
    private(set) var passwordError: String?
    private(set) var authError: String?

    var onRegisterSuccess: (() -> Void)?
    var onGoToLogin: (() -> Void)?

    private let auth: AuthServicing

    init(auth: AuthServicing) {
        self.auth = auth
    }

    func register(name: String, email: String, password: String) {
        nameError = nil; emailError = nil; passwordError = nil; authError = nil

        var valid = true
        if !FieldValidators.isNonEmpty(name)       { nameError = "Введите имя"; valid = false }
        if !FieldValidators.isValidEmail(email)    { emailError = "Введите корректный email"; valid = false }
        if !FieldValidators.isValidPassword(password) { passwordError = "Пароль — минимум 6 символов"; valid = false }
        guard valid else { return }

        switch auth.register(name: name, phone: "", email: email, password: password) {
        case .success:
            onRegisterSuccess?()
        case .failure(.emailTaken):
            authError = "Этот email уже зарегистрирован"
        case .failure:
            authError = "Ошибка регистрации"
        }
    }

    func goToLogin() {
        onGoToLogin?()
    }
}
