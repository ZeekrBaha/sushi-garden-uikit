import UIKit

// MARK: - PromotionBannerCell

final class PromotionBannerCell: UITableViewCell {
    static let reuseIdentifier = "PromotionBannerCell"

    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with promotion: Promotion) {
        iconView.image = UIImage(systemName: promotion.imageName)
        titleLabel.text = promotion.title
        descriptionLabel.text = promotion.description
    }

    private func setup() {
        backgroundColor = AppColor.surface
        layer.cornerRadius = Spacing.cardRadius
        selectionStyle = .none

        iconView.tintColor = AppColor.accent
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 48),
            iconView.heightAnchor.constraint(equalToConstant: 48),
        ])

        titleLabel.font = AppFont.productTitle
        titleLabel.textColor = AppColor.textPrimary
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        descriptionLabel.font = AppFont.weight
        descriptionLabel.textColor = AppColor.textSecondary
        descriptionLabel.numberOfLines = 0
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false

        let textStack = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel])
        textStack.axis = .vertical
        textStack.spacing = Spacing.xs
        textStack.translatesAutoresizingMaskIntoConstraints = false

        let row = UIStackView(arrangedSubviews: [iconView, textStack])
        row.axis = .horizontal
        row.spacing = Spacing.m
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Spacing.m),
            row.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Spacing.m),
            row.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.m),
            row.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Spacing.m),
        ])
    }
}

// MARK: - PromotionsViewController

final class PromotionsViewController: UIViewController {
    private static let promotions: [Promotion] = [
        Promotion(id: "1", title: "Бесплатная доставка",
                  description: "При заказе от 1500 ₽", imageName: "bicycle"),
        Promotion(id: "2", title: "Ролл в подарок",
                  description: "При первом заказе — бесплатный ролл", imageName: "gift"),
        Promotion(id: "3", title: "Скидка 10%",
                  description: "По вторникам на все сеты", imageName: "percent"),
        Promotion(id: "4", title: "Комбо-обед",
                  description: "Суп + ролл + напиток за 799 ₽", imageName: "fork.knife"),
    ]

    private let tableView = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColor.background
        title = "Акции"
        setupTableView()
    }

    private func setupTableView() {
        tableView.backgroundColor = AppColor.background
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.contentInset = UIEdgeInsets(top: Spacing.m, left: 0, bottom: Spacing.m, right: 0)
        tableView.register(PromotionBannerCell.self, forCellReuseIdentifier: PromotionBannerCell.reuseIdentifier)
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
}

extension PromotionsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Self.promotions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: PromotionBannerCell.reuseIdentifier,
            for: indexPath) as? PromotionBannerCell
        else { return UITableViewCell() }
        cell.configure(with: Self.promotions[indexPath.row])
        return cell
    }
}
