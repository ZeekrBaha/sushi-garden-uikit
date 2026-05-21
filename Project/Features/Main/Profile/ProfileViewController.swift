import UIKit

final class ProfileViewController: UIViewController {
    let viewModel: ProfileViewModel

    private let avatarContainer = UIView()
    private let initialsLabel = UILabel()
    private let nameLabel = UILabel()
    private let phoneLabel = UILabel()
    private let emailLabel = UILabel()
    private let logoutButton = UIButton(type: .system)

    init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColor.background
        title = "Профиль"
        setupAvatar()
        setupInfoRows()
        setupLogoutButton()
        populateProfile()
    }

    private func setupAvatar() {
        avatarContainer.backgroundColor = AppColor.elevated
        avatarContainer.layer.cornerRadius = 40
        avatarContainer.translatesAutoresizingMaskIntoConstraints = false

        initialsLabel.font = AppFont.price
        initialsLabel.textColor = AppColor.textPrimary
        initialsLabel.textAlignment = .center
        initialsLabel.translatesAutoresizingMaskIntoConstraints = false
        avatarContainer.addSubview(initialsLabel)

        view.addSubview(avatarContainer)
        NSLayoutConstraint.activate([
            avatarContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Spacing.xl),
            avatarContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            avatarContainer.widthAnchor.constraint(equalToConstant: 80),
            avatarContainer.heightAnchor.constraint(equalToConstant: 80),

            initialsLabel.centerXAnchor.constraint(equalTo: avatarContainer.centerXAnchor),
            initialsLabel.centerYAnchor.constraint(equalTo: avatarContainer.centerYAnchor),
        ])
    }

    private func setupInfoRows() {
        nameLabel.font = AppFont.weight
        nameLabel.textColor = AppColor.textPrimary
        phoneLabel.font = AppFont.weight
        phoneLabel.textColor = AppColor.textPrimary
        emailLabel.font = AppFont.weight
        emailLabel.textColor = AppColor.textPrimary

        let nameRow = makeInfoRow(icon: "person", label: nameLabel)
        let phoneRow = makeInfoRow(icon: "phone", label: phoneLabel)
        let emailRow = makeInfoRow(icon: "envelope", label: emailLabel)

        let stack = UIStackView(arrangedSubviews: [nameRow, phoneRow, emailRow])
        stack.axis = .vertical
        stack.spacing = Spacing.m
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: avatarContainer.bottomAnchor, constant: Spacing.xl),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Spacing.m),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.m),
        ])
    }

    private func makeInfoRow(icon: String, label: UILabel) -> UIStackView {
        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = AppColor.textSecondary
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20),
        ])

        let row = UIStackView(arrangedSubviews: [iconView, label])
        row.axis = .horizontal
        row.spacing = Spacing.m
        row.alignment = .center
        return row
    }

    private func setupLogoutButton() {
        logoutButton.setTitle("Выйти из аккаунта", for: .normal)
        logoutButton.setTitleColor(AppColor.textPrimary, for: .normal)
        logoutButton.backgroundColor = AppColor.accent
        logoutButton.titleLabel?.font = AppFont.productTitle
        logoutButton.layer.cornerRadius = Spacing.cardRadius
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        logoutButton.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)
        view.addSubview(logoutButton)
        NSLayoutConstraint.activate([
            logoutButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Spacing.m),
            logoutButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.m),
            logoutButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -Spacing.m),
            logoutButton.heightAnchor.constraint(equalToConstant: 54),
        ])
    }

    private func populateProfile() {
        guard let profile = viewModel.profile else { return }
        let words = profile.name.split(separator: " ")
        let initials = words.prefix(2).compactMap { $0.first }.map { String($0) }.joined()
        initialsLabel.text = initials.uppercased()
        nameLabel.text = profile.name
        phoneLabel.text = profile.phone
        emailLabel.text = profile.email
    }

    @objc private func logoutTapped() {
        viewModel.logout()
    }
}
