import UIKit

final class ProductDetailViewController: UIViewController {
    let viewModel: ProductDetailViewModel

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let heroImageView = UIImageView()
    private let nameLabel = UILabel()
    private let weightLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let priceLabel = UILabel()
    private let stepper = QuantityStepper()
    private let addButton = PrimaryButton()

    init(viewModel: ProductDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColor.background
        setupLayout()
        populate()
    }

    private func setupLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = Spacing.m
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        heroImageView.contentMode = .scaleAspectFill
        heroImageView.clipsToBounds = true
        heroImageView.backgroundColor = AppColor.elevated
        heroImageView.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.textColor = AppColor.textPrimary
        nameLabel.font = AppFont.productTitle
        nameLabel.numberOfLines = 0
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        weightLabel.textColor = AppColor.textSecondary
        weightLabel.font = AppFont.weight
        weightLabel.translatesAutoresizingMaskIntoConstraints = false

        descriptionLabel.textColor = AppColor.textSecondary
        descriptionLabel.font = AppFont.caption
        descriptionLabel.numberOfLines = 0
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false

        priceLabel.textColor = AppColor.textPrimary
        priceLabel.font = AppFont.price
        priceLabel.translatesAutoresizingMaskIntoConstraints = false

        addButton.setTitle("В корзину", for: .normal)
        addButton.addTarget(self, action: #selector(addToCartTapped), for: .touchUpInside)

        contentStack.addArrangedSubview(heroImageView)
        contentStack.addArrangedSubview(nameLabel)
        contentStack.addArrangedSubview(weightLabel)
        contentStack.addArrangedSubview(descriptionLabel)
        contentStack.addArrangedSubview(priceLabel)
        contentStack.addArrangedSubview(stepper)
        contentStack.addArrangedSubview(addButton)
        contentStack.setCustomSpacing(Spacing.xl, after: stepper)

        contentStack.isLayoutMarginsRelativeArrangement = true
        contentStack.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 0, leading: Spacing.m, bottom: Spacing.xl, trailing: Spacing.m)
        contentStack.setCustomSpacing(Spacing.s, after: nameLabel)
        contentStack.setCustomSpacing(0, after: heroImageView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            heroImageView.heightAnchor.constraint(equalToConstant: 240),
        ])
    }

    private func populate() {
        let product = viewModel.product
        nameLabel.text = product.name
        weightLabel.text = "\(product.weightGrams) г"
        descriptionLabel.text = product.description.isEmpty ? nil : product.description
        priceLabel.text = "\(product.price) ₽"
        heroImageView.image = UIImage(named: product.imageName) ?? UIImage(systemName: "photo")
        nameLabel.accessibilityIdentifier = "detail.name"
        weightLabel.accessibilityIdentifier = "detail.weight"
        priceLabel.accessibilityIdentifier = "detail.price"
        descriptionLabel.accessibilityIdentifier = "detail.description"
        addButton.accessibilityIdentifier = "detail.addButton"
        stepper.setIdentifierPrefix("detail.stepper")
    }

    @objc private func addToCartTapped() {
        viewModel.addToCart(quantity: stepper.count)
    }
}
