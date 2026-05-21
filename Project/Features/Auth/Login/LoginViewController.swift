import UIKit

final class LoginViewController: UIViewController {
    let viewModel: LoginViewModel

    private let titleLabel = UILabel()
    private let emailField = FormField(placeholder: "Email")
    private let passwordField = FormField(placeholder: "Пароль", isSecure: true)
    private let authErrorLabel = UILabel()
    private let loginButton = PrimaryButton()
    private let toggleButton = UIButton(type: .system)

    init(viewModel: LoginViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = AppColor.background

        titleLabel.text = "Войти"
        titleLabel.textColor = AppColor.textPrimary
        titleLabel.font = AppFont.productTitle
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        authErrorLabel.textColor = AppColor.accent
        authErrorLabel.font = AppFont.caption
        authErrorLabel.textAlignment = .center
        authErrorLabel.isHidden = true
        authErrorLabel.translatesAutoresizingMaskIntoConstraints = false

        loginButton.setTitle("Войти", for: .normal)
        loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)

        toggleButton.setTitle("Нет аккаунта? Зарегистрироваться", for: .normal)
        toggleButton.setTitleColor(AppColor.textSecondary, for: .normal)
        toggleButton.titleLabel?.font = AppFont.caption
        toggleButton.translatesAutoresizingMaskIntoConstraints = false
        toggleButton.addTarget(self, action: #selector(toggleTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [
            titleLabel, emailField, passwordField, authErrorLabel, loginButton, toggleButton
        ])
        stack.axis = .vertical
        stack.spacing = Spacing.m
        stack.setCustomSpacing(Spacing.xl, after: titleLabel)
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Spacing.m),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.m),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    @objc private func loginTapped() {
        viewModel.login(
            email: emailField.textField.text ?? "",
            password: passwordField.textField.text ?? ""
        )
        refreshErrors()
    }

    private func refreshErrors() {
        emailField.errorMessage = viewModel.emailError
        passwordField.errorMessage = viewModel.passwordError
        authErrorLabel.text = viewModel.authError
        authErrorLabel.isHidden = viewModel.authError == nil
    }

    @objc private func toggleTapped() {
        viewModel.goToRegister()
    }
}
