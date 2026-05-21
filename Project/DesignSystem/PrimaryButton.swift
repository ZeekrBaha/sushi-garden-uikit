import UIKit

final class PrimaryButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func configure() {
        backgroundColor = AppColor.accent
        setTitleColor(.white, for: .normal)
        titleLabel?.font = AppFont.categoryTab
        layer.cornerRadius = Spacing.cardRadius
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 52).isActive = true
    }
}
