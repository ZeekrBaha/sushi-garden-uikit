import UIKit

final class AuthFormField: UIView {
    let textField = UITextField()
    private let fieldLabel = UILabel()
    private let inputContainer = UIView()
    private let errorLabel = UILabel()
    private var eyeButton: UIButton?

    var errorMessage: String? {
        didSet {
            errorLabel.text = errorMessage
            errorLabel.isHidden = errorMessage == nil
        }
    }

    init(label: String, placeholder: String, isSecure: Bool = false) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setup(label: label, placeholder: placeholder, isSecure: isSecure)
    }

    required init?(coder: NSCoder) { fatalError() }

    func setFieldIdentifier(_ id: String) {
        textField.accessibilityIdentifier = id
    }

    private func setup(label: String, placeholder: String, isSecure: Bool) {
        fieldLabel.text = label.uppercased()
        fieldLabel.font = AppFont.sen(12)
        fieldLabel.textColor = AuthPalette.label
        fieldLabel.translatesAutoresizingMaskIntoConstraints = false

        inputContainer.backgroundColor = AuthPalette.fieldBackground
        inputContainer.layer.cornerRadius = 8
        inputContainer.translatesAutoresizingMaskIntoConstraints = false

        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: AuthPalette.placeholder]
        )
        textField.textColor = AuthPalette.fieldText
        textField.font = AppFont.sen(13)
        textField.isSecureTextEntry = isSecure
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.translatesAutoresizingMaskIntoConstraints = false

        errorLabel.textColor = AppColor.accent
        errorLabel.font = AppFont.caption
        errorLabel.isHidden = true
        errorLabel.numberOfLines = 0
        errorLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubview(fieldLabel)
        addSubview(inputContainer)
        inputContainer.addSubview(textField)
        addSubview(errorLabel)

        var textTrailing: NSLayoutXAxisAnchor = inputContainer.trailingAnchor
        var textTrailingInset: CGFloat = -16

        if isSecure {
            let eye = UIButton(type: .system)
            eye.setImage(UIImage(systemName: "eye.fill"), for: .normal)
            eye.tintColor = AuthPalette.icon
            eye.translatesAutoresizingMaskIntoConstraints = false
            eye.addTarget(self, action: #selector(toggleVisibility), for: .touchUpInside)
            inputContainer.addSubview(eye)
            NSLayoutConstraint.activate([
                eye.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -16),
                eye.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
                eye.widthAnchor.constraint(equalToConstant: 28),
                eye.heightAnchor.constraint(equalToConstant: 28),
            ])
            eyeButton = eye
            textTrailing = eye.leadingAnchor
            textTrailingInset = -8
        }

        NSLayoutConstraint.activate([
            fieldLabel.topAnchor.constraint(equalTo: topAnchor),
            fieldLabel.leadingAnchor.constraint(equalTo: leadingAnchor),

            inputContainer.topAnchor.constraint(equalTo: fieldLabel.bottomAnchor, constant: 8),
            inputContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            inputContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            inputContainer.heightAnchor.constraint(equalToConstant: 56),

            textField.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 16),
            textField.trailingAnchor.constraint(equalTo: textTrailing, constant: textTrailingInset),
            textField.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),

            errorLabel.topAnchor.constraint(equalTo: inputContainer.bottomAnchor, constant: Spacing.xs),
            errorLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            errorLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            errorLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    @objc private func toggleVisibility() {
        textField.isSecureTextEntry.toggle()
        let name = textField.isSecureTextEntry ? "eye.fill" : "eye.slash.fill"
        eyeButton?.setImage(UIImage(systemName: name), for: .normal)
    }
}
