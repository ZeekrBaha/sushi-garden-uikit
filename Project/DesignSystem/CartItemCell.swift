import UIKit

final class CartItemCell: UITableViewCell {
    static let reuseIdentifier = "CartItemCell"

    let nameLabel = UILabel()
    let priceLabel = UILabel()
    private let productImageView = UIImageView()
    private let stepper = QuantityStepper()

    var onQuantityChanged: ((Int) -> Void)?
    var onRemove: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with item: CartItem) {
        nameLabel.text = item.product.name
        priceLabel.text = "\(item.subtotal) ₽"
        productImageView.image = UIImage(named: item.product.imageName) ?? UIImage(systemName: "photo")
        stepper.setCount(item.quantity)
        accessibilityIdentifier = "cart.item.\(item.product.id)"
        stepper.setIdentifierPrefix("cart.item.\(item.product.id).stepper")
    }

    func simulateIncrementTap() {
        stepper.increment()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onQuantityChanged = nil
        onRemove = nil
        productImageView.image = nil
        stepper.setCount(1)
    }

    private func setup() {
        selectionStyle = .none
        backgroundColor = AppColor.surface
        contentView.backgroundColor = AppColor.surface

        productImageView.contentMode = .scaleAspectFill
        productImageView.clipsToBounds = true
        productImageView.layer.cornerRadius = Spacing.cardRadius / 2
        productImageView.backgroundColor = AppColor.elevated
        productImageView.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.textColor = AppColor.textPrimary
        nameLabel.font = AppFont.productTitle
        nameLabel.numberOfLines = 2
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        priceLabel.textColor = AppColor.textPrimary
        priceLabel.font = AppFont.price
        priceLabel.translatesAutoresizingMaskIntoConstraints = false

        stepper.translatesAutoresizingMaskIntoConstraints = false
        stepper.onCountChanged = { [weak self] count in self?.onQuantityChanged?(count) }

        contentView.addSubview(productImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(priceLabel)
        contentView.addSubview(stepper)

        NSLayoutConstraint.activate([
            productImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Spacing.m),
            productImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            productImageView.widthAnchor.constraint(equalToConstant: 64),
            productImageView.heightAnchor.constraint(equalToConstant: 64),
            productImageView.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: Spacing.m),
            productImageView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -Spacing.m),

            nameLabel.topAnchor.constraint(equalTo: productImageView.topAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: productImageView.trailingAnchor, constant: Spacing.m),
            nameLabel.trailingAnchor.constraint(equalTo: stepper.leadingAnchor, constant: -Spacing.s),

            priceLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: Spacing.xs),
            priceLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            priceLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -Spacing.m),

            stepper.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.m),
            stepper.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            stepper.widthAnchor.constraint(equalToConstant: 120),
        ])
    }
}
