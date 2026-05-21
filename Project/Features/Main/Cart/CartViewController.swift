import UIKit
import Combine

final class CartViewController: UIViewController {
    let viewModel: CartViewModel
    private var cancellables = Set<AnyCancellable>()
    private let tableView = UITableView()
    private let emptyLabel = UILabel()
    private let footerView = CartFooterView()

    init(viewModel: CartViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColor.background
        setupTableView()
        setupEmptyState()
        bindViewModel()
    }

    private func setupTableView() {
        tableView.backgroundColor = AppColor.background
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 96
        tableView.register(CartItemCell.self, forCellReuseIdentifier: CartItemCell.reuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false

        footerView.translatesAutoresizingMaskIntoConstraints = false
        footerView.checkoutButton.addTarget(self, action: #selector(checkoutTapped), for: .touchUpInside)

        view.addSubview(tableView)
        view.addSubview(footerView)

        NSLayoutConstraint.activate([
            footerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            footerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            footerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: footerView.topAnchor),
        ])
    }

    private func setupEmptyState() {
        emptyLabel.text = "Корзина пуста"
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
        viewModel.$items
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                guard let self else { return }
                tableView.reloadData()
                let empty = items.isEmpty
                emptyLabel.isHidden = !empty
                footerView.isHidden = empty
                footerView.configure(totalPrice: viewModel.totalPrice)
            }
            .store(in: &cancellables)
    }

    @objc private func checkoutTapped() {
        viewModel.checkout()
    }
}

extension CartViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: CartItemCell.reuseIdentifier, for: indexPath) as? CartItemCell
        else { fatalError("Failed to dequeue CartItemCell") }
        guard indexPath.row < viewModel.items.count else {
            return UITableViewCell()
        }
        let item = viewModel.items[indexPath.row]
        cell.configure(with: item)
        cell.onQuantityChanged = { [weak self] qty in
            self?.viewModel.setQuantity(qty, for: item.product.id)
        }
        cell.onRemove = { [weak self] in
            self?.viewModel.remove(productId: item.product.id)
        }
        return cell
    }
}

extension CartViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard indexPath.row < viewModel.items.count else { return nil }
        let item = viewModel.items[indexPath.row]
        let delete = UIContextualAction(style: .destructive, title: "Удалить") { [weak self] _, _, completion in
            self?.viewModel.remove(productId: item.product.id)
            completion(true)
        }
        return UISwipeActionsConfiguration(actions: [delete])
    }
}

// MARK: - CartFooterView

final class CartFooterView: UIView {
    let checkoutButton = PrimaryButton()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(totalPrice: Int) {
        checkoutButton.setTitle("Оформить заказ · \(totalPrice) ₽", for: .normal)
    }

    private func setup() {
        backgroundColor = AppColor.surface
        checkoutButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(checkoutButton)

        NSLayoutConstraint.activate([
            checkoutButton.topAnchor.constraint(equalTo: topAnchor, constant: Spacing.m),
            checkoutButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Spacing.m),
            checkoutButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.m),
            checkoutButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Spacing.m),
        ])
    }
}
