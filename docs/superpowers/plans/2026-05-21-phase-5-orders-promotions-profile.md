# Phase 5: Orders / Promotions / Profile — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the three placeholder view controllers in MainTabCoordinator with real Orders, Promotions, and Profile screens, each backed by an MVVM-C coordinator following the patterns established in earlier phases.

**Architecture:** `OrdersCoordinator`, `PromotionsCoordinator`, and `ProfileCoordinator` replace the three `makePlaceholder` calls in `MainTabCoordinator.start()`. `OrdersViewModel` mirrors `CartViewModel` (sync init + `dropFirst` reactive updates). `ProfileViewModel` reads `currentUser` once and fires a callback chain on logout that propagates to `AppCoordinator` via `isAuthenticatedPublisher`. Promotions is a static, non-reactive table.

**Tech Stack:** Swift 5.9, iOS 17, UIKit, Combine, XcodeGen (`project.yml` uses directory globs — run `xcodegen generate` before each build/test step after adding new files)

---

## File Map

| Action | Path | Purpose |
|--------|------|---------|
| Create | `Project/Models/Promotion.swift` | Plain Promotion struct |
| Create | `Project/Features/Main/Orders/OrdersViewModel.swift` | Reactive wrapper over OrdersServicing |
| Create | `Project/Features/Main/Orders/OrdersViewController.swift` | UITableView + OrderSummaryCell + Order.Status extension |
| Create | `Project/Features/Main/Orders/OrdersCoordinator.swift` | Wires Orders VM + VC |
| Create | `Project/Features/Main/Profile/ProfileViewModel.swift` | Reads currentUser, calls auth.logout() |
| Create | `Project/Features/Main/Profile/ProfileViewController.swift` | Avatar + info rows + logout button |
| Create | `Project/Features/Main/Profile/ProfileCoordinator.swift` | Wires Profile VM + VC, owns onLogout callback |
| Create | `Project/Features/Main/Promotions/PromotionsViewController.swift` | Static table of promotion cards + PromotionBannerCell |
| Create | `Project/Features/Main/Promotions/PromotionsCoordinator.swift` | Wires Promotions VC |
| Create | `Tests/Features/Main/Orders/OrdersViewModelTests.swift` | 6 tests for OrdersViewModel |
| Create | `Tests/Features/Main/Orders/OrdersCoordinatorTests.swift` | 1 test for OrdersCoordinator |
| Create | `Tests/Features/Main/Profile/ProfileViewModelTests.swift` | 3 tests for ProfileViewModel |
| Create | `Tests/Features/Main/Profile/ProfileCoordinatorTests.swift` | 2 tests for ProfileCoordinator |
| Modify | `Project/Features/Main/MainTabCoordinator.swift` | Replace 3 makePlaceholder calls with child coordinators |
| Modify | `Tests/Features/Main/MainTabCoordinatorTests.swift` | Add 3 tests for the new real tabs |

---

## Task 1: Promotion Model

**Files:**
- Create: `Project/Models/Promotion.swift`

- [ ] **Step 1: Create the Promotion struct**

```swift
import Foundation

struct Promotion: Identifiable {
    let id: String
    let title: String
    let description: String
    let imageName: String
}
```

- [ ] **Step 2: Regenerate project and verify it compiles**

```bash
cd /Users/baha/Desktop/llm-ai-projects/sushi-garden-uikit
xcodegen generate
```

Expected: `✅ Done` with no errors.

- [ ] **Step 3: Commit**

```bash
git add Project/Models/Promotion.swift
git commit -m "feat: add Promotion model"
```

---

## Task 2: OrdersViewModel + Tests

**Files:**
- Create: `Project/Features/Main/Orders/OrdersViewModel.swift`
- Create: `Tests/Features/Main/Orders/OrdersViewModelTests.swift`

- [ ] **Step 1: Write the failing tests**

Create `Tests/Features/Main/Orders/OrdersViewModelTests.swift`:

```swift
import XCTest
import Combine
@testable import SushiGarden

final class OrdersViewModelTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()

    override func tearDown() {
        cancellables = []
        super.tearDown()
    }

    private func drainMainQueue() {
        let exp = expectation(description: "main queue drained")
        DispatchQueue.main.async { exp.fulfill() }
        wait(for: [exp], timeout: 1.0)
    }

    private func makePlacedOrder(in service: InMemoryOrdersService) {
        let product = Product(id: "p1", name: "Roll", categoryId: "rolls",
                              weightGrams: 200, price: 800, imageName: "roll", description: "")
        let address = DeliveryAddress(city: "А", street: "Б", building: "1")
        _ = service.placeOrder(items: [CartItem(product: product, quantity: 1)], address: address)
    }

    func test_orders_initiallyEmpty() {
        let sut = OrdersViewModel(service: InMemoryOrdersService())
        XCTAssertTrue(sut.orders.isEmpty)
    }

    func test_initialOrders_populatedFromService() {
        let service = InMemoryOrdersService()
        makePlacedOrder(in: service)
        let sut = OrdersViewModel(service: service)
        XCTAssertEqual(sut.orders.count, 1)
    }

    func test_orders_updatesWhenServiceEmits() {
        let service = InMemoryOrdersService()
        let sut = OrdersViewModel(service: service)
        makePlacedOrder(in: service)
        drainMainQueue()
        XCTAssertEqual(sut.orders.count, 1)
    }

    func test_isEmpty_trueWhenNoOrders() {
        let sut = OrdersViewModel(service: InMemoryOrdersService())
        XCTAssertTrue(sut.isEmpty)
    }

    func test_isEmpty_falseWhenOrdersExist() {
        let service = InMemoryOrdersService()
        makePlacedOrder(in: service)
        let sut = OrdersViewModel(service: service)
        XCTAssertFalse(sut.isEmpty)
    }

    func test_orders_publishesOnChange() {
        let service = InMemoryOrdersService()
        let sut = OrdersViewModel(service: service)
        var count = 0
        sut.$orders.dropFirst().sink { _ in count += 1 }.store(in: &cancellables)
        makePlacedOrder(in: service)
        drainMainQueue()
        XCTAssertEqual(count, 1)
    }
}
```

- [ ] **Step 2: Regenerate project and run tests — expect FAIL**

```bash
cd /Users/baha/Desktop/llm-ai-projects/sushi-garden-uikit && xcodegen generate
```

Then run tests. Expected: FAIL with "Cannot find type 'OrdersViewModel'".

- [ ] **Step 3: Implement OrdersViewModel**

Create `Project/Features/Main/Orders/OrdersViewModel.swift`:

```swift
import Foundation
import Combine

final class OrdersViewModel {
    @Published private(set) var orders: [Order] = []
    var isEmpty: Bool { orders.isEmpty }

    private let service: OrdersServicing
    private var cancellables = Set<AnyCancellable>()

    init(service: OrdersServicing) {
        self.service = service
        self.orders = service.orders
        service.ordersPublisher
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] orders in self?.orders = orders }
            .store(in: &cancellables)
    }
}
```

- [ ] **Step 4: Regenerate project and run tests — expect PASS**

```bash
cd /Users/baha/Desktop/llm-ai-projects/sushi-garden-uikit && xcodegen generate
```

Run: `xcodebuild test -scheme SushiGarden -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' 2>&1 | grep -E "(PASS|FAIL|error:)"`

Expected: All 6 `OrdersViewModelTests` PASS.

- [ ] **Step 5: Commit**

```bash
git add Project/Features/Main/Orders/OrdersViewModel.swift \
        Tests/Features/Main/Orders/OrdersViewModelTests.swift
git commit -m "feat: add OrdersViewModel with tests"
```

---

## Task 3: OrdersViewController

**Files:**
- Create: `Project/Features/Main/Orders/OrdersViewController.swift`

This file contains `OrdersViewController`, `OrderSummaryCell`, and an `Order.Status` display extension. No VC-level unit tests (consistent with all other VCs in the project).

- [ ] **Step 1: Create OrdersViewController.swift**

Create `Project/Features/Main/Orders/OrdersViewController.swift`:

```swift
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
```

- [ ] **Step 2: Regenerate project and verify it compiles**

```bash
cd /Users/baha/Desktop/llm-ai-projects/sushi-garden-uikit && xcodegen generate
```

Then build: `xcodebuild build -scheme SushiGarden -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' 2>&1 | grep -E "(BUILD|error:)"`

Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Commit**

```bash
git add Project/Features/Main/Orders/OrdersViewController.swift
git commit -m "feat: add OrdersViewController with OrderSummaryCell"
```

---

## Task 4: OrdersCoordinator + Tests

**Files:**
- Create: `Project/Features/Main/Orders/OrdersCoordinator.swift`
- Create: `Tests/Features/Main/Orders/OrdersCoordinatorTests.swift`

- [ ] **Step 1: Write the failing test**

Create `Tests/Features/Main/Orders/OrdersCoordinatorTests.swift`:

```swift
import XCTest
@testable import SushiGarden

final class OrdersCoordinatorTests: XCTestCase {
    private func makeSUT() -> (OrdersCoordinator, UINavigationController) {
        let nav = UINavigationController()
        let sut = OrdersCoordinator(navigationController: nav, container: AppContainer())
        return (sut, nav)
    }

    func test_start_setsOrdersViewControllerAsRoot() {
        let (sut, nav) = makeSUT()
        sut.start()
        XCTAssertTrue(nav.topViewController is OrdersViewController)
    }
}
```

- [ ] **Step 2: Regenerate and run test — expect FAIL**

```bash
cd /Users/baha/Desktop/llm-ai-projects/sushi-garden-uikit && xcodegen generate
```

Expected: FAIL with "Cannot find type 'OrdersCoordinator'".

- [ ] **Step 3: Implement OrdersCoordinator**

Create `Project/Features/Main/Orders/OrdersCoordinator.swift`:

```swift
import UIKit

final class OrdersCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    let navigationController: UINavigationController
    private let container: AppContainer

    init(navigationController: UINavigationController = UINavigationController(),
         container: AppContainer) {
        self.navigationController = navigationController
        self.container = container
    }

    func start() {
        let vm = OrdersViewModel(service: container.orders)
        let vc = OrdersViewController(viewModel: vm)
        navigationController.setViewControllers([vc], animated: false)
    }
}
```

- [ ] **Step 4: Regenerate and run test — expect PASS**

```bash
cd /Users/baha/Desktop/llm-ai-projects/sushi-garden-uikit && xcodegen generate
```

Run tests. Expected: `test_start_setsOrdersViewControllerAsRoot` PASSES.

- [ ] **Step 5: Commit**

```bash
git add Project/Features/Main/Orders/OrdersCoordinator.swift \
        Tests/Features/Main/Orders/OrdersCoordinatorTests.swift
git commit -m "feat: add OrdersCoordinator with tests"
```

---

## Task 5: ProfileViewModel + Tests

**Files:**
- Create: `Project/Features/Main/Profile/ProfileViewModel.swift`
- Create: `Tests/Features/Main/Profile/ProfileViewModelTests.swift`

- [ ] **Step 1: Write the failing tests**

Create `Tests/Features/Main/Profile/ProfileViewModelTests.swift`:

```swift
import XCTest
@testable import SushiGarden

final class ProfileViewModelTests: XCTestCase {
    private func makeLoggedInAuth() -> InMemoryAuthService {
        let auth = InMemoryAuthService()
        _ = auth.login(email: "test@sushi.ru", password: "secret1")
        return auth
    }

    func test_profile_exposesCurrentUser() {
        let auth = makeLoggedInAuth()
        let sut = ProfileViewModel(auth: auth)
        XCTAssertEqual(sut.profile, auth.currentUser)
    }

    func test_logout_callsAuthLogout() {
        let auth = makeLoggedInAuth()
        let sut = ProfileViewModel(auth: auth)
        sut.logout()
        XCTAssertFalse(auth.isAuthenticated)
        XCTAssertNil(auth.currentUser)
    }

    func test_logout_firesOnLogoutCompleted() {
        let auth = makeLoggedInAuth()
        let sut = ProfileViewModel(auth: auth)
        var called = false
        sut.onLogoutCompleted = { called = true }
        sut.logout()
        XCTAssertTrue(called)
    }
}
```

- [ ] **Step 2: Regenerate and run tests — expect FAIL**

```bash
cd /Users/baha/Desktop/llm-ai-projects/sushi-garden-uikit && xcodegen generate
```

Expected: FAIL with "Cannot find type 'ProfileViewModel'".

- [ ] **Step 3: Implement ProfileViewModel**

Create `Project/Features/Main/Profile/ProfileViewModel.swift`:

```swift
import Foundation

final class ProfileViewModel {
    let profile: UserProfile?
    var onLogoutCompleted: (() -> Void)?

    private let auth: AuthServicing

    init(auth: AuthServicing) {
        self.auth = auth
        self.profile = auth.currentUser
    }

    func logout() {
        auth.logout()
        onLogoutCompleted?()
    }
}
```

- [ ] **Step 4: Regenerate and run tests — expect PASS**

```bash
cd /Users/baha/Desktop/llm-ai-projects/sushi-garden-uikit && xcodegen generate
```

Run tests. Expected: All 3 `ProfileViewModelTests` PASS.

- [ ] **Step 5: Commit**

```bash
git add Project/Features/Main/Profile/ProfileViewModel.swift \
        Tests/Features/Main/Profile/ProfileViewModelTests.swift
git commit -m "feat: add ProfileViewModel with tests"
```

---

## Task 6: ProfileViewController

**Files:**
- Create: `Project/Features/Main/Profile/ProfileViewController.swift`

No VC-level unit tests (consistent with all other VCs in the project).

- [ ] **Step 1: Create ProfileViewController.swift**

Create `Project/Features/Main/Profile/ProfileViewController.swift`:

```swift
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
```

- [ ] **Step 2: Regenerate and verify it compiles**

```bash
cd /Users/baha/Desktop/llm-ai-projects/sushi-garden-uikit && xcodegen generate
```

Build: `xcodebuild build -scheme SushiGarden -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' 2>&1 | grep -E "(BUILD|error:)"`

Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Commit**

```bash
git add Project/Features/Main/Profile/ProfileViewController.swift
git commit -m "feat: add ProfileViewController"
```

---

## Task 7: ProfileCoordinator + Tests

**Files:**
- Create: `Project/Features/Main/Profile/ProfileCoordinator.swift`
- Create: `Tests/Features/Main/Profile/ProfileCoordinatorTests.swift`

- [ ] **Step 1: Write the failing tests**

Create `Tests/Features/Main/Profile/ProfileCoordinatorTests.swift`:

```swift
import XCTest
@testable import SushiGarden

final class ProfileCoordinatorTests: XCTestCase {
    private func makeSUT(
        onLogout: @escaping () -> Void = {}
    ) -> (ProfileCoordinator, UINavigationController) {
        let nav = UINavigationController()
        let sut = ProfileCoordinator(
            navigationController: nav,
            container: AppContainer(),
            onLogout: onLogout)
        return (sut, nav)
    }

    func test_start_setsProfileViewControllerAsRoot() {
        let (sut, nav) = makeSUT()
        sut.start()
        XCTAssertTrue(nav.topViewController is ProfileViewController)
    }

    func test_logout_callsOnLogout() {
        var loggedOut = false
        let auth = InMemoryAuthService()
        _ = auth.login(email: "test@sushi.ru", password: "secret1")
        let container = AppContainer(auth: auth)
        let nav = UINavigationController()
        let sut = ProfileCoordinator(
            navigationController: nav,
            container: container,
            onLogout: { loggedOut = true })
        sut.start()
        let profileVC = nav.topViewController as? ProfileViewController
        profileVC?.viewModel.logout()
        XCTAssertTrue(loggedOut)
    }
}
```

- [ ] **Step 2: Regenerate and run tests — expect FAIL**

```bash
cd /Users/baha/Desktop/llm-ai-projects/sushi-garden-uikit && xcodegen generate
```

Expected: FAIL with "Cannot find type 'ProfileCoordinator'".

- [ ] **Step 3: Implement ProfileCoordinator**

Create `Project/Features/Main/Profile/ProfileCoordinator.swift`:

```swift
import UIKit

final class ProfileCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    let navigationController: UINavigationController
    private let container: AppContainer
    private let onLogout: () -> Void

    init(navigationController: UINavigationController = UINavigationController(),
         container: AppContainer,
         onLogout: @escaping () -> Void) {
        self.navigationController = navigationController
        self.container = container
        self.onLogout = onLogout
    }

    func start() {
        let vm = ProfileViewModel(auth: container.auth)
        vm.onLogoutCompleted = { [weak self] in self?.onLogout() }
        let vc = ProfileViewController(viewModel: vm)
        navigationController.setViewControllers([vc], animated: false)
    }
}
```

- [ ] **Step 4: Regenerate and run tests — expect PASS**

```bash
cd /Users/baha/Desktop/llm-ai-projects/sushi-garden-uikit && xcodegen generate
```

Run tests. Expected: Both `ProfileCoordinatorTests` PASS.

- [ ] **Step 5: Commit**

```bash
git add Project/Features/Main/Profile/ProfileCoordinator.swift \
        Tests/Features/Main/Profile/ProfileCoordinatorTests.swift
git commit -m "feat: add ProfileCoordinator with tests"
```

---

## Task 8: PromotionsViewController + PromotionsCoordinator

**Files:**
- Create: `Project/Features/Main/Promotions/PromotionsViewController.swift`
- Create: `Project/Features/Main/Promotions/PromotionsCoordinator.swift`

No unit tests: `PromotionsViewController` has no logic (static data) and `PromotionsCoordinator` has no callbacks to verify beyond Task 9's integration via `MainTabCoordinatorTests`.

- [ ] **Step 1: Create PromotionsViewController.swift**

Create `Project/Features/Main/Promotions/PromotionsViewController.swift`:

```swift
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
    private let promotions: [Promotion] = [
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
        promotions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: PromotionBannerCell.reuseIdentifier,
            for: indexPath) as? PromotionBannerCell
        else { return UITableViewCell() }
        cell.configure(with: promotions[indexPath.row])
        return cell
    }
}
```

- [ ] **Step 2: Create PromotionsCoordinator.swift**

Create `Project/Features/Main/Promotions/PromotionsCoordinator.swift`:

```swift
import UIKit

final class PromotionsCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    let navigationController: UINavigationController

    init(navigationController: UINavigationController = UINavigationController()) {
        self.navigationController = navigationController
    }

    func start() {
        let vc = PromotionsViewController()
        navigationController.setViewControllers([vc], animated: false)
    }
}
```

- [ ] **Step 3: Regenerate and verify it compiles**

```bash
cd /Users/baha/Desktop/llm-ai-projects/sushi-garden-uikit && xcodegen generate
```

Build: `xcodebuild build -scheme SushiGarden -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' 2>&1 | grep -E "(BUILD|error:)"`

Expected: `BUILD SUCCEEDED`

- [ ] **Step 4: Commit**

```bash
git add Project/Features/Main/Promotions/PromotionsViewController.swift \
        Project/Features/Main/Promotions/PromotionsCoordinator.swift
git commit -m "feat: add PromotionsViewController and PromotionsCoordinator"
```

---

## Task 9: Wire MainTabCoordinator + extend MainTabCoordinatorTests

**Files:**
- Modify: `Project/Features/Main/MainTabCoordinator.swift`
- Modify: `Tests/Features/Main/MainTabCoordinatorTests.swift`

- [ ] **Step 1: Write the 3 new failing tests**

Open `Tests/Features/Main/MainTabCoordinatorTests.swift` and append these three tests inside the `MainTabCoordinatorTests` class (before the closing `}`):

```swift
func test_start_ordersTabContainsOrdersViewController() {
    let sut = makeSUT()
    sut.start()
    let nav = sut.tabBarController.viewControllers?[1] as? UINavigationController
    XCTAssertTrue(nav?.topViewController is OrdersViewController)
}

func test_start_promotionsTabContainsPromotionsViewController() {
    let sut = makeSUT()
    sut.start()
    let nav = sut.tabBarController.viewControllers?[2] as? UINavigationController
    XCTAssertTrue(nav?.topViewController is PromotionsViewController)
}

func test_start_profileTabContainsProfileViewController() {
    let sut = makeSUT()
    sut.start()
    let nav = sut.tabBarController.viewControllers?[4] as? UINavigationController
    XCTAssertTrue(nav?.topViewController is ProfileViewController)
}
```

- [ ] **Step 2: Run tests — expect 3 new tests FAIL (existing pass)**

Run: `xcodebuild test -scheme SushiGarden -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' 2>&1 | grep -E "(PASS|FAIL|error:)"`

Expected: The 3 new tests fail because tabs 1, 2, 4 are still placeholder `UIViewController`s, not nav controllers.

- [ ] **Step 3: Replace the 3 placeholder tabs in MainTabCoordinator**

Replace the entire `start()` method and add `handleLogout()` in `Project/Features/Main/MainTabCoordinator.swift`.

The new file content:

```swift
import UIKit
import Combine

final class MainTabCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []

    let tabBarController: UITabBarController
    private let container: AppContainer
    private var cancellables = Set<AnyCancellable>()

    init(container: AppContainer) {
        self.container = container
        self.tabBarController = UITabBarController()
    }

    func start() {
        let catalogNav = UINavigationController()
        catalogNav.navigationBar.isHidden = true
        let catalogCoordinator = CatalogCoordinator(navigationController: catalogNav, container: container)
        addChild(catalogCoordinator)
        catalogCoordinator.start()
        catalogNav.tabBarItem = UITabBarItem(
            title: "Каталог", image: UIImage(systemName: "fork.knife"), tag: 0)

        let ordersNav = UINavigationController()
        let ordersCoordinator = OrdersCoordinator(navigationController: ordersNav, container: container)
        addChild(ordersCoordinator)
        ordersCoordinator.start()
        ordersNav.tabBarItem = UITabBarItem(
            title: "Заказы", image: UIImage(systemName: "list.bullet"), tag: 1)

        let promotionsNav = UINavigationController()
        let promotionsCoordinator = PromotionsCoordinator(navigationController: promotionsNav)
        addChild(promotionsCoordinator)
        promotionsCoordinator.start()
        promotionsNav.tabBarItem = UITabBarItem(
            title: "Акции", image: UIImage(systemName: "tag"), tag: 2)

        let cartNav = UINavigationController()
        cartNav.navigationBar.isHidden = true
        let cartCoordinator = CartCoordinator(
            navigationController: cartNav,
            container: container,
            onSwitchToOrders: { [weak self] in
                self?.tabBarController.selectedIndex = 1
            })
        addChild(cartCoordinator)
        cartCoordinator.start()
        cartNav.tabBarItem = UITabBarItem(
            title: "Корзина", image: UIImage(systemName: "bag"), tag: 3)

        let profileNav = UINavigationController()
        let profileCoordinator = ProfileCoordinator(
            navigationController: profileNav,
            container: container,
            onLogout: { [weak self] in self?.handleLogout() })
        addChild(profileCoordinator)
        profileCoordinator.start()
        profileNav.tabBarItem = UITabBarItem(
            title: "Профиль", image: UIImage(systemName: "person"), tag: 4)

        tabBarController.viewControllers = [catalogNav, ordersNav, promotionsNav, cartNav, profileNav]
        tabBarController.tabBar.barTintColor = AppColor.surface
        tabBarController.tabBar.tintColor = AppColor.textPrimary
        tabBarController.tabBar.unselectedItemTintColor = AppColor.inactive

        bindCartBadge()
    }

    private func handleLogout() {
        // auth.logout() was already called by ProfileViewModel; AppCoordinator handles the transition
    }

    private func bindCartBadge() {
        container.cart.itemsPublisher
            .map { items -> String? in
                let count = items.reduce(0) { $0 + $1.quantity }
                return count > 0 ? "\(count)" : nil
            }
            .sink { [weak self] badge in
                self?.tabBarController.viewControllers?[3].tabBarItem.badgeValue = badge
            }
            .store(in: &cancellables)
    }
}
```

- [ ] **Step 4: Run all tests — expect all PASS**

```bash
cd /Users/baha/Desktop/llm-ai-projects/sushi-garden-uikit && xcodegen generate
```

Run: `xcodebuild test -scheme SushiGarden -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' 2>&1 | grep -E "(Test Suite|PASS|FAIL|error:)"`

Expected: All tests PASS, including the 3 new `MainTabCoordinatorTests`. Verify the full suite is green (previously 134 tests; Phase 5 adds ~13 more for ~147 total).

- [ ] **Step 5: Commit**

```bash
git add Project/Features/Main/MainTabCoordinator.swift \
        Tests/Features/Main/MainTabCoordinatorTests.swift
git commit -m "feat: wire Phase 5 — Orders, Promotions, Profile tabs in MainTabCoordinator"
```
