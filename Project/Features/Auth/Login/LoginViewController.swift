import UIKit

final class LoginViewController: UIViewController {
    let viewModel: LoginViewModel

    private let emailField = AuthFormField(label: "Почта", placeholder: "example@gmail.com")
    private let passwordField = AuthFormField(label: "Пароль", placeholder: "**********", isSecure: true)
    private let authErrorLabel = UILabel()

    init(viewModel: LoginViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColor.background
        setupTitle()
        setupSheet()
    }

    private func setupTitle() {
        let label = UILabel()
        label.text = "Войти"
        label.textColor = .white
        label.font = AppFont.sen(29, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 48),
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }

    private func setupSheet() {
        let sheet = UIView()
        sheet.backgroundColor = .white
        sheet.layer.cornerRadius = 20
        sheet.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        sheet.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sheet)
        NSLayoutConstraint.activate([
            sheet.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sheet.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sheet.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sheet.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.78),
        ])

        emailField.setFieldIdentifier("login.email")
        emailField.textField.keyboardType = .emailAddress
        passwordField.setFieldIdentifier("login.password")

        authErrorLabel.textColor = AppColor.accent
        authErrorLabel.font = AppFont.caption
        authErrorLabel.textAlignment = .center
        authErrorLabel.numberOfLines = 0
        authErrorLabel.isHidden = true
        authErrorLabel.accessibilityIdentifier = "login.authError"

        let loginButton = makeSubmitButton(title: "ВОЙТИ", identifier: "login.loginButton", action: #selector(loginTapped))

        let toggleContainer = makeToggleRow(
            prompt: "У вас нет аккаунта?",
            actionTitle: "РЕГИСТРАЦИЯ",
            identifier: "login.registerLink",
            action: #selector(toggleTapped)
        )

        let spacer = UIView()
        spacer.heightAnchor.constraint(equalToConstant: 48).isActive = true

        let stack = UIStackView(arrangedSubviews: [
            emailField, passwordField, spacer, loginButton, toggleContainer, authErrorLabel
        ])
        stack.axis = .vertical
        stack.spacing = 18
        stack.setCustomSpacing(6, after: loginButton)
        stack.translatesAutoresizingMaskIntoConstraints = false
        sheet.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: sheet.topAnchor, constant: 38),
            stack.leadingAnchor.constraint(equalTo: sheet.leadingAnchor, constant: 22),
            stack.trailingAnchor.constraint(equalTo: sheet.trailingAnchor, constant: -22),
        ])
    }

    private func makeSubmitButton(title: String, identifier: String, action: Selector) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = AppFont.sen(15, weight: .bold)
        btn.backgroundColor = AppColor.accent
        btn.layer.cornerRadius = 10
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.accessibilityIdentifier = identifier
        btn.addTarget(self, action: action, for: .touchUpInside)
        btn.heightAnchor.constraint(equalToConstant: 56).isActive = true
        return btn
    }

    private func makeToggleRow(prompt: String, actionTitle: String, identifier: String, action: Selector) -> UIView {
        let promptLabel = UILabel()
        promptLabel.text = prompt
        promptLabel.font = AppFont.sen(14)
        promptLabel.textColor = AuthPalette.secondaryAction

        let actionButton = UIButton(type: .system)
        actionButton.setTitle(actionTitle, for: .normal)
        actionButton.setTitleColor(AppColor.accent, for: .normal)
        actionButton.titleLabel?.font = AppFont.sen(14, weight: .bold)
        actionButton.accessibilityIdentifier = identifier
        actionButton.addTarget(self, action: action, for: .touchUpInside)

        let row = UIStackView(arrangedSubviews: [promptLabel, actionButton])
        row.axis = .horizontal
        row.spacing = 4
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false

        let container = UIView()
        container.addSubview(row)
        NSLayoutConstraint.activate([
            row.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            row.topAnchor.constraint(equalTo: container.topAnchor),
            row.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        return container
    }

    @objc private func loginTapped() {
        viewModel.login(
            email: emailField.textField.text ?? "",
            password: passwordField.textField.text ?? ""
        )
        emailField.errorMessage = viewModel.emailError
        passwordField.errorMessage = viewModel.passwordError
        authErrorLabel.text = viewModel.authError
        authErrorLabel.isHidden = viewModel.authError == nil
    }

    @objc private func toggleTapped() {
        viewModel.goToRegister()
    }
}
