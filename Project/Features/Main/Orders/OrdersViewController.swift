import UIKit
import Combine

// MARK: - Order.Status display helpers

private extension Order.Status {
    var displayName: String {
        switch self {
        case .placed:     return "Принят"
        case .cooking:    return "Готовится"
        case .delivering: return "Доставляется"
        case .delivered:  return "Доставлен"
        }
    }

    var badgeColor: UIColor {
        switch self {
        case .placed:     return AppColor.inactive
        case .cooking:    return .systemOrange
        case .delivering: return .systemBlue
        case .delivered:  return .systemGreen
        }
    }
}

// MARK: - OrderSummaryCell

final class OrderSummaryCell: UITableViewCell {
    static let reuseIdentifier = "OrderSummaryCell"

    private let dateLabel = UILabel()
    private let itemCountLabel = UILabel()
    private let totalLabel = UILabel()
    private let statusBadge = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with order: Order) {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        dateLabel.text = formatter.string(from: order.createdAt)

        let itemCount = order.items.reduce(0) { $0 + $1.quantity }
        itemCountLabel.text = "\(itemCount) \(itemCount == 1 ? "товар" : "товара")"

        totalLabel.text = "₽\(order.total)"
        statusBadge.text = " \(order.status.displayName) "
        statusBadge.backgroundColor = order.status.badgeColor
    }

    private func setup() {
        backgroundColor = AppColor.surface
        layer.cornerRadius = Spacing.cardRadius
        selectionStyle = .none

        dateLabel.font = AppFont.weight
        dateLabel.textColor = AppColor.textSecondary
        dateLabel.translatesAutoresizingMaskIntoConstraints = false

        itemCountLabel.font = AppFont.weight
        itemCountLabel.textColor = AppColor.textSecondary
        itemCountLabel.translatesAutoresizingMaskIntoConstraints = false

        totalLabel.font = AppFont.price
        totalLabel.textColor = AppColor.textPrimary
        totalLabel.translatesAutoresizingMaskIntoConstraints = false

        statusBadge.font = AppFont.caption
        statusBadge.textColor = AppColor.textPrimary
        statusBadge.textAlignment = .center
        statusBadge.layer.cornerRadius = 8
        statusBadge.layer.masksToBounds = true
        statusBadge.translatesAutoresizingMaskIntoConstraints = false

        let topRow = UIStackView(arrangedSubviews: [dateLabel, itemCountLabel])
        topRow.axis = .horizontal
        topRow.spacing = Spacing.s
        topRow.translatesAutoresizingMaskIntoConstraints = false

        let bottomRow = UIStackView(arrangedSubviews: [totalLabel, statusBadge])
        bottomRow.axis = .horizontal
        bottomRow.spacing = Spacing.s
        bottomRow.alignment = .center
        bottomRow.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [topRow, bottomRow])
        stack.axis = .vertical
        stack.spacing = Spacing.xs
        stack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Spacing.m),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Spacing.m),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.m),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Spacing.m),
        ])
    }
}

// MARK: - OrdersViewController

final class OrdersViewController: UIViewController {
    let viewModel: OrdersViewModel
    private var cancellables = Set<AnyCancellable>()
    private let tableView = UITableView()
    private let emptyLabel = UILabel()

    init(viewModel: OrdersViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColor.background
        title = "Заказы"
        setupTableView()
        setupEmptyState()
        bindViewModel()
    }

    private func setupTableView() {
        tableView.backgroundColor = AppColor.background
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.contentInset = UIEdgeInsets(top: Spacing.m, left: 0, bottom: Spacing.m, right: 0)
        tableView.register(OrderSummaryCell.self, forCellReuseIdentifier: OrderSummaryCell.reuseIdentifier)
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

    private func setupEmptyState() {
        emptyLabel.text = "Заказов пока нет"
        emptyLabel.textColor = AppColor.textSecondary
        emptyLabel.font = AppFont.productTitle
        emptyLabel.textAlignment = .center
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyLabel)
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    private func bindViewModel() {
        viewModel.$orders
            .receive(on: DispatchQueue.main)
            .sink { [weak self] orders in
                guard let self else { return }
                tableView.reloadData()
                emptyLabel.isHidden = !orders.isEmpty
            }
            .store(in: &cancellables)
    }
}

extension OrdersViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.orders.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < viewModel.orders.count,
              let cell = tableView.dequeueReusableCell(
                  withIdentifier: OrderSummaryCell.reuseIdentifier,
                  for: indexPath) as? OrderSummaryCell
        else { return UITableViewCell() }
        cell.configure(with: viewModel.orders[indexPath.row])
        return cell
    }
}
