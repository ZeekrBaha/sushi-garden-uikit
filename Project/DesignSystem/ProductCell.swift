import UIKit

final class ProductCell: UICollectionViewCell {
    static let reuseIdentifier = "ProductCell"

    let nameLabel = UILabel()
    let weightLabel = UILabel()
    let priceLabel = UILabel()
    private let imageView = UIImageView()
    private let addButton = UIButton(type: .system)

    var onAddTapped: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with product: Product) {
        nameLabel.text = product.name
        weightLabel.text = "\(product.weightGrams) г"
        priceLabel.text = "\(product.price) ₽"
        imageView.image = UIImage(named: product.imageName) ?? UIImage(systemName: "photo")
    }

    func simulateAddTap() {
        addTapped()
    }

    private func setup() {
        contentView.backgroundColor = AppColor.surface
        contentView.layer.cornerRadius = Spacing.cardRadius
        contentView.clipsToBounds = true

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = AppColor.elevated
        imageView.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.textColor = AppColor.textPrimary
        nameLabel.font = AppFont.productTitle
        nameLabel.numberOfLines = 2
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        weightLabel.textColor = AppColor.textSecondary
        weightLabel.font = AppFont.caption
        weightLabel.translatesAutoresizingMaskIntoConstraints = false

        priceLabel.textColor = AppColor.textPrimary
        priceLabel.font = AppFont.price
        priceLabel.translatesAutoresizingMaskIntoConstraints = false

        addButton.setTitle("+", for: .normal)
        addButton.backgroundColor = AppColor.accent
        addButton.setTitleColor(.white, for: .normal)
        addButton.layer.cornerRadius = Spacing.cardRadius / 2
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)

        contentView.addSubview(imageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(weightLabel)
        contentView.addSubview(priceLabel)
        contentView.addSubview(addButton)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.heightAnchor.constraint(equalToConstant: 120),

            nameLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: Spacing.s),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Spacing.s),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.s),

            weightLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: Spacing.xs),
            weightLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Spacing.s),
            weightLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.s),

            priceLabel.topAnchor.constraint(equalTo: weightLabel.bottomAnchor, constant: Spacing.s),
            priceLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Spacing.s),

            addButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.s),
            addButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Spacing.s),
            addButton.widthAnchor.constraint(equalToConstant: 36),
            addButton.heightAnchor.constraint(equalToConstant: 36),
        ])
    }

    @objc private func addTapped() {
        onAddTapped?()
    }
}
