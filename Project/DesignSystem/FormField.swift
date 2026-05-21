import UIKit

final class FormField: UIView {
    let textField = UITextField()
    private let inputContainer = UIView()
    private let errorLabel = UILabel()

    var errorMessage: String? {
        didSet {
            errorLabel.text = errorMessage
            errorLabel.isHidden = errorMessage == nil
        }
    }

    init(placeholder: String, isSecure: Bool = false) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setup(placeholder: placeholder, isSecure: isSecure)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setup(placeholder: String, isSecure: Bool) {
        inputContainer.backgroundColor = AppColor.elevated
        inputContainer.layer.cornerRadius = Spacing.cardRadius
        inputContainer.translatesAutoresizingMaskIntoConstraints = false

        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: AppColor.textSecondary]
        )
        textField.textColor = AppColor.textPrimary
        textField.font = AppFont.weight
        textField.isSecureTextEntry = isSecure
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.translatesAutoresizingMaskIntoConstraints = false

        errorLabel.textColor = AppColor.accent
        errorLabel.font = AppFont.caption
        errorLabel.isHidden = true
        errorLabel.numberOfLines = 0
        errorLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubview(inputContainer)
        inputContainer.addSubview(textField)
        addSubview(errorLabel)

        NSLayoutConstraint.activate([
            inputContainer.topAnchor.constraint(equalTo: topAnchor),
            inputContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            inputContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            inputContainer.heightAnchor.constraint(equalToConstant: 52),

            textField.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: Spacing.m),
            textField.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -Spacing.m),
            textField.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),

            errorLabel.topAnchor.constraint(equalTo: inputContainer.bottomAnchor, constant: Spacing.xs),
            errorLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            errorLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            errorLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
}
