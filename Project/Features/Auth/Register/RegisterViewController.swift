import UIKit

final class RegisterViewController: UIViewController {
    let viewModel: RegisterViewModel

    private let titleLabel = UILabel()
    private let nameField = FormField(placeholder: "Имя")
    private let phoneField = FormField(placeholder: "Телефон")
    private let emailField = FormField(placeholder: "Email")
    private let passwordField = FormField(placeholder: "Пароль", isSecure: true)
    private let authErrorLabel = UILabel()
    private let registerButton = PrimaryButton()
    private let toggleButton = UIButton(type: .system)

    init(viewModel: RegisterViewModel) {
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

        titleLabel.text = "Регистрация"
        titleLabel.textColor = AppColor.textPrimary
        titleLabel.font = AppFont.productTitle
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        authErrorLabel.textColor = AppColor.accent
        authErrorLabel.font = AppFont.caption
        authErrorLabel.textAlignment = .center
        authErrorLabel.isHidden = true
        authErrorLabel.translatesAutoresizingMaskIntoConstraints = false

        registerButton.setTitle("Зарегистрироваться", for: .normal)
        registerButton.addTarget(self, action: #selector(registerTapped), for: .touchUpInside)

        toggleButton.setTitle("Уже есть аккаунт? Войти", for: .normal)
        toggleButton.setTitleColor(AppColor.textSecondary, for: .normal)
        toggleButton.titleLabel?.font = AppFont.caption
        toggleButton.translatesAutoresizingMaskIntoConstraints = false
        toggleButton.addTarget(self, action: #selector(toggleTapped), for: .touchUpInside)

        let fields = UIStackView(arrangedSubviews: [
            titleLabel, nameField, phoneField, emailField, passwordField,
            authErrorLabel, registerButton, toggleButton
        ])
        fields.axis = .vertical
        fields.spacing = Spacing.m
        fields.setCustomSpacing(Spacing.xl, after: titleLabel)
        fields.translatesAutoresizingMaskIntoConstraints = false

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(fields)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            fields.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: Spacing.xl),
            fields.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: Spacing.m),
            fields.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -Spacing.m),
            fields.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -Spacing.xl),
            fields.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -Spacing.m * 2),
        ])

        nameField.setFieldIdentifier("register.name")
        phoneField.setFieldIdentifier("register.phone")
        emailField.setFieldIdentifier("register.email")
        passwordField.setFieldIdentifier("register.password")
        registerButton.accessibilityIdentifier = "register.registerButton"
        toggleButton.accessibilityIdentifier = "register.loginLink"
        authErrorLabel.accessibilityIdentifier = "register.authError"
    }

    @objc private func registerTapped() {
        viewModel.register(
            name: nameField.textField.text ?? "",
            phone: phoneField.textField.text ?? "",
            email: emailField.textField.text ?? "",
            password: passwordField.textField.text ?? ""
        )
        refreshErrors()
    }

    private func refreshErrors() {
        nameField.errorMessage = viewModel.nameError
        phoneField.errorMessage = viewModel.phoneError
        emailField.errorMessage = viewModel.emailError
        passwordField.errorMessage = viewModel.passwordError
        authErrorLabel.text = viewModel.authError
        authErrorLabel.isHidden = viewModel.authError == nil
    }

    @objc private func toggleTapped() {
        viewModel.goToLogin()
    }
}
