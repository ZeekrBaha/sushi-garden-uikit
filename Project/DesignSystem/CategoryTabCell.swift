import UIKit

final class CategoryTabCell: UICollectionViewCell {
    static let reuseIdentifier = "CategoryTabCell"

    let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(name: String, isSelected: Bool) {
        titleLabel.text = name
        contentView.backgroundColor = isSelected ? AppColor.accent : AppColor.elevated
    }

    private func setup() {
        contentView.backgroundColor = AppColor.elevated
        contentView.layer.cornerRadius = Spacing.cardRadius
        contentView.clipsToBounds = true

        titleLabel.textColor = AppColor.textPrimary
        titleLabel.font = AppFont.categoryTab
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Spacing.m),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.m),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }
}
