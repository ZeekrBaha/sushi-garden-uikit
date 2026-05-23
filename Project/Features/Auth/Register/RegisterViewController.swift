import UIKit

final class RegisterViewController: UIViewController {
    let viewModel: RegisterViewModel

    private let nameField = AuthFormField(label: "Имя", placeholder: "Александр")
    private let emailField = AuthFormField(label: "Почта", placeholder: "example@gmail.com")
    private let passwordField = AuthFormField(label: "Пароль", placeholder: "**********", isSecure: true)
    private let authErrorLabel = UILabel()

    private let checkboxView = UIView()
    private let checkmarkImage = UIImageView()
    private var consentChecked = false
    private var registerButton: UIButton!

    init(viewModel: RegisterViewModel) {
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
        label.text = "Регистрация"
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

        nameField.setFieldIdentifier("register.name")
        emailField.setFieldIdentifier("register.email")
        emailField.textField.keyboardType = .emailAddress
        passwordField.setFieldIdentifier("register.password")

        authErrorLabel.textColor = AppColor.accent
        authErrorLabel.font = AppFont.caption
        authErrorLabel.textAlignment = .center
        authErrorLabel.numberOfLines = 0
        authErrorLabel.isHidden = true
        authErrorLabel.accessibilityIdentifier = "register.authError"

        registerButton = makeSubmitButton(title: "РЕГИСТРАЦИЯ", identifier: "register.registerButton", action: #selector(registerTapped))
        registerButton.isEnabled = false
        registerButton.alpha = 0.95

        let consentView = makeConsentView()
        let toggleContainer = makeToggleRow(
            prompt: "Уже есть аккаунт?",
            actionTitle: "ВОЙТИ",
            identifier: "register.loginLink",
            action: #selector(toggleTapped)
        )

        let stack = UIStackView(arrangedSubviews: [
            nameField, emailField, passwordField, consentView,
            registerButton, toggleContainer, authErrorLabel
        ])
        stack.axis = .vertical
        stack.spacing = 18
        stack.setCustomSpacing(6, after: registerButton)
        stack.translatesAutoresizingMaskIntoConstraints = false
        sheet.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: sheet.topAnchor, constant: 38),
            stack.leadingAnchor.constraint(equalTo: sheet.leadingAnchor, constant: 22),
            stack.trailingAnchor.constraint(equalTo: sheet.trailingAnchor, constant: -22),
        ])
    }

    private func makeConsentView() -> UIView {
        checkboxView.layer.borderWidth = 1.4
        checkboxView.layer.borderColor = AuthPalette.checkboxBorder.cgColor
        checkboxView.layer.cornerRadius = 3
        checkboxView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            checkboxView.widthAnchor.constraint(equalToConstant: 18),
            checkboxView.heightAnchor.constraint(equalToConstant: 18),
        ])

        checkmarkImage.image = UIImage(systemName: "checkmark")
        checkmarkImage.tintColor = .white
        checkmarkImage.contentMode = .scaleAspectFit
        checkmarkImage.isHidden = true
        checkmarkImage.translatesAutoresizingMaskIntoConstraints = false
        checkboxView.addSubview(checkmarkImage)
        NSLayoutConstraint.activate([
            checkmarkImage.centerXAnchor.constraint(equalTo: checkboxView.centerXAnchor),
            checkmarkImage.centerYAnchor.constraint(equalTo: checkboxView.centerYAnchor),
            checkmarkImage.widthAnchor.constraint(equalToConstant: 10),
            checkmarkImage.heightAnchor.constraint(equalToConstant: 10),
        ])

        let consentLabel = UILabel()
        consentLabel.text = "Я согласен с Условиями предоставления услуг и Политикой конфиденциальности"
        consentLabel.font = AppFont.sen(12)
        consentLabel.textColor = UIColor(red: 0.55, green: 0.58, blue: 0.68, alpha: 1)
        consentLabel.numberOfLines = 0

        let row = UIStackView(arrangedSubviews: [checkboxView, consentLabel])
        row.axis = .horizontal
        row.spacing = 14
        row.alignment = .top
        row.translatesAutoresizingMaskIntoConstraints = false

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.accessibilityIdentifier = "register.consent"
        container.addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: container.topAnchor),
            row.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            row.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(consentTapped))
        container.addGestureRecognizer(tap)
        container.isUserInteractionEnabled = true
        return container
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

    @objc private func consentTapped() {
        consentChecked.toggle()
        checkboxView.backgroundColor = consentChecked ? AppColor.accent : .clear
        checkmarkImage.isHidden = !consentChecked
        registerButton.isEnabled = consentChecked
        registerButton.alpha = consentChecked ? 1.0 : 0.95
    }

    @objc private func registerTapped() {
        viewModel.register(
            name: nameField.textField.text ?? "",
            email: emailField.textField.text ?? "",
            password: passwordField.textField.text ?? ""
        )
        nameField.errorMessage = viewModel.nameError
        emailField.errorMessage = viewModel.emailError
        passwordField.errorMessage = viewModel.passwordError
        authErrorLabel.text = viewModel.authError
        authErrorLabel.isHidden = viewModel.authError == nil
    }

    @objc private func toggleTapped() {
        viewModel.goToLogin()
    }
}
