# Sushi Garden (UIKit) — Phase 4: Cart + Checkout — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Cart screen (tab 3) and Checkout screen so a user can review their cart, enter a delivery address via an interactive MapKit map with a draggable pin and reverse geocoding, place an order, and be switched to the Orders tab automatically.

**Architecture:** `CartCoordinator` owns a `UINavigationController` and replaces the cart placeholder in `MainTabCoordinator`. It starts with `CartViewController` (UITableView of `CartItemCell` rows, `CartFooterView`, empty state) bound to `CartViewModel`, which wraps `CartServicing`. On "Checkout", `CartCoordinator` pushes `CheckoutViewController` with a `CheckoutViewModel` holding a cart snapshot, `CLGeocoder` (injected via a `Geocoding` protocol for testability), and `OrdersServicing`. On order placement the VM calls `cart.clear()` then fires `onOrderPlaced` → coordinator pops to root and calls a `onSwitchToOrders` closure provided by `MainTabCoordinator`.

**Tech Stack:** Swift 5.9, iOS 17, UIKit + Combine, MapKit, CoreLocation, XCTest.

---

## Phase roadmap context

| Phase | Status |
|---|---|
| 1. Foundation & App Skeleton | ✅ Complete |
| 2. Auth flow | ✅ Complete |
| 3. Catalog + Detail + Tab shell | ✅ Complete |
| **4. Cart + Checkout** | **← this plan** |
| 5. Orders / Promotions / Profile | next |

---

## Existing infrastructure (do not re-implement)

- `Project/DesignSystem/QuantityStepper.swift` — `count`, `increment()`, `decrement()`, `onCountChanged`
- `Project/DesignSystem/PrimaryButton.swift` — red 52pt CTA button
- `Project/Services/Cart/CartServicing.swift` — `items`, `itemsPublisher`, `totalPrice`, `add`, `setQuantity(_:for:)`, `remove(productId:)`, `clear()`
- `Project/Services/Orders/OrdersServicing.swift` + `InMemoryOrdersService` — `placeOrder(items:address:) -> Order`
- `Project/Core/DI/AppContainer.swift` — `cart: CartServicing`, `orders: OrdersServicing`
- `Project/Models/CartItem.swift` — `product`, `quantity`, `subtotal`
- `Project/Models/DeliveryAddress.swift` — `city`, `street`, `building`, `formatted`
- `Project/Features/Main/MainTabCoordinator.swift` — tab 3 is currently a plain `UIViewController` placeholder

---

## File structure introduced in Phase 4

```
Project/
  DesignSystem/
    CartItemCell.swift          UITableViewCell: image, name, price, QuantityStepper
  Features/Main/Cart/
    CartCoordinator.swift       Cart root → push Checkout → onOrderPlaced → switch tab
    CartViewModel.swift         @Published items + totalPrice; remove/setQuantity
    CartViewController.swift    UITableView + CartFooterView + empty state
    Checkout/
      CheckoutViewModel.swift   Geocoding protocol + VM; snapshot items; placeOrder
      CheckoutViewController.swift  MKMapView + draggable pin + address + CTA

Tests/
  DesignSystem/
    CartItemCellTests.swift
  Features/Main/Cart/
    CartViewModelTests.swift
    CartViewControllerTests.swift
    CartCoordinatorTests.swift
    Checkout/
      CheckoutViewModelTests.swift
      CheckoutViewControllerTests.swift
```

Modified:
- `Project/DesignSystem/QuantityStepper.swift` — add `setCount(_:)`
- `Tests/DesignSystem/QuantityStepperTests.swift` — add 3 tests for `setCount`
- `Project/Features/Main/MainTabCoordinator.swift` — replace cart placeholder with `CartCoordinator`
- `Tests/Features/Main/MainTabCoordinatorTests.swift` — update tab-3 assertions

---

## Task 1: Add `setCount(_:)` to QuantityStepper (TDD)

**Files:**
- Modify: `Project/DesignSystem/QuantityStepper.swift`
- Modify: `Tests/DesignSystem/QuantityStepperTests.swift`

Cart item cells need to initialize the stepper to the item's existing quantity (e.g. 3) rather than always starting at 1.

- [ ] **Step 1: Add 3 failing tests to `Tests/DesignSystem/QuantityStepperTests.swift`**

Append these three test methods inside the existing `QuantityStepperTests` class (after the last existing test):

```swift
    func test_setCount_updatesCount() {
        let sut = QuantityStepper()
        sut.setCount(3)
        XCTAssertEqual(sut.count, 3)
    }

    func test_setCount_belowOne_doesNothing() {
        let sut = QuantityStepper()
        sut.setCount(0)
        XCTAssertEqual(sut.count, 1)
    }

    func test_setCount_doesNotFireOnCountChanged() {
        let sut = QuantityStepper()
        var called = false
        sut.onCountChanged = { _ in called = true }
        sut.setCount(3)
        XCTAssertFalse(called)
    }
```

- [ ] **Step 2: Run `xcodegen generate`**

```bash
cd /Users/baha/Desktop/llm-ai-projects/sushi-garden-uikit && xcodegen generate
```

Expected: `✔ Writing project` (no errors)

- [ ] **Step 3: Run tests to verify they fail**

Use XcodeBuildMCP `test_sim` with `-only-testing:SushiGardenTests/QuantityStepperTests`.
Expected: FAIL — `value of type 'QuantityStepper' has no member 'setCount'`

- [ ] **Step 4: Add `setCount(_:)` to `Project/DesignSystem/QuantityStepper.swift`**

Add this method after `decrement()`, before `private func setup()`:

```swift
    func setCount(_ newCount: Int) {
        guard newCount >= 1 else { return }
        count = newCount
        countLabel.text = "\(count)"
    }
```

- [ ] **Step 5: Run tests to verify they pass**

Use XcodeBuildMCP `test_sim` with `-only-testing:SushiGardenTests/QuantityStepperTests`.
Expected: PASS (9 tests).

- [ ] **Step 6: Commit**

```bash
git add Project/DesignSystem/QuantityStepper.swift Tests/DesignSystem/QuantityStepperTests.swift
git commit -m "feat: add setCount to QuantityStepper for cart item initialization"
```

---

## Task 2: CartItemCell (TDD)

**Files:**
- Create: `Project/DesignSystem/CartItemCell.swift`
- Create: `Tests/DesignSystem/CartItemCellTests.swift`

- [ ] **Step 1: Create `Tests/DesignSystem/CartItemCellTests.swift`**

```swift
import XCTest
@testable import SushiGarden

final class CartItemCellTests: XCTestCase {
    private func makeItem(quantity: Int = 2) -> CartItem {
        CartItem(
            product: Product(id: "p1", name: "Хикари", categoryId: "rolls",
                             weightGrams: 255, price: 620, imageName: "hikari", description: ""),
            quantity: quantity)
    }

    func test_configure_setsNameLabel() {
        let sut = CartItemCell()
        sut.configure(with: makeItem())
        XCTAssertEqual(sut.nameLabel.text, "Хикари")
    }

    func test_configure_setPriceLabel_asSubtotal() {
        let sut = CartItemCell()
        sut.configure(with: makeItem(quantity: 2))
        XCTAssertEqual(sut.priceLabel.text, "1240 ₽") // 620 × 2
    }

    func test_onQuantityChanged_calledWhenStepperIncrements() {
        let sut = CartItemCell()
        sut.configure(with: makeItem(quantity: 1))
        var received: Int?
        sut.onQuantityChanged = { received = $0 }
        sut.simulateIncrementTap()
        XCTAssertEqual(received, 2)
    }
}
```

- [ ] **Step 2: Create `Project/DesignSystem/CartItemCell.swift`**

```swift
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
    }

    func simulateIncrementTap() {
        stepper.increment()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onQuantityChanged = nil
        onRemove = nil
        productImageView.image = nil
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
```

- [ ] **Step 3: Run `xcodegen generate`**

```bash
cd /Users/baha/Desktop/llm-ai-projects/sushi-garden-uikit && xcodegen generate
```

- [ ] **Step 4: Run tests to verify they pass**

Use XcodeBuildMCP `test_sim` with `-only-testing:SushiGardenTests/CartItemCellTests`.
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add Project/DesignSystem/CartItemCell.swift Tests/DesignSystem/CartItemCellTests.swift
git commit -m "feat: add CartItemCell design system component"
```

---

## Task 3: CartViewModel (TDD)

**Files:**
- Create: `Project/Features/Main/Cart/CartViewModel.swift`
- Create: `Tests/Features/Main/Cart/CartViewModelTests.swift`

- [ ] **Step 1: Create `Tests/Features/Main/Cart/CartViewModelTests.swift`**

```swift
import XCTest
import Combine
@testable import SushiGarden

final class CartViewModelTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()

    override func tearDown() {
        cancellables = []
        super.tearDown()
    }

    private func makeProduct(_ id: String = "p1", price: Int = 500) -> Product {
        Product(id: id, name: "Test", categoryId: "rolls",
                weightGrams: 200, price: price, imageName: "test", description: "")
    }

    func test_items_initiallyEmpty() {
        let sut = CartViewModel(cart: InMemoryCartService())
        XCTAssertTrue(sut.items.isEmpty)
    }

    func test_items_updatesWhenProductAdded() {
        let cart = InMemoryCartService()
        let sut = CartViewModel(cart: cart)
        cart.add(makeProduct())
        XCTAssertEqual(sut.items.count, 1)
    }

    func test_totalPrice_sumsSubtotals() {
        let cart = InMemoryCartService()
        let sut = CartViewModel(cart: cart)
        cart.add(makeProduct("p1", price: 500))
        cart.add(makeProduct("p2", price: 300))
        XCTAssertEqual(sut.totalPrice, 800)
    }

    func test_isEmpty_trueWhenNoItems() {
        let sut = CartViewModel(cart: InMemoryCartService())
        XCTAssertTrue(sut.isEmpty)
    }

    func test_isEmpty_falseWhenHasItems() {
        let cart = InMemoryCartService()
        let sut = CartViewModel(cart: cart)
        cart.add(makeProduct())
        XCTAssertFalse(sut.isEmpty)
    }

    func test_setQuantity_forwardsToService() {
        let cart = InMemoryCartService()
        let sut = CartViewModel(cart: cart)
        cart.add(makeProduct())
        sut.setQuantity(3, for: "p1")
        XCTAssertEqual(cart.items.first?.quantity, 3)
    }

    func test_remove_forwardsToService() {
        let cart = InMemoryCartService()
        let sut = CartViewModel(cart: cart)
        cart.add(makeProduct())
        sut.remove(productId: "p1")
        XCTAssertTrue(cart.items.isEmpty)
    }

    func test_checkout_firesOnCheckout() {
        let sut = CartViewModel(cart: InMemoryCartService())
        var called = false
        sut.onCheckout = { called = true }
        sut.checkout()
        XCTAssertTrue(called)
    }

    func test_items_publishesOnChange() {
        let cart = InMemoryCartService()
        let sut = CartViewModel(cart: cart)
        var count = 0
        sut.$items.dropFirst().sink { _ in count += 1 }.store(in: &cancellables)
        cart.add(makeProduct())
        XCTAssertEqual(count, 1)
    }
}
```

- [ ] **Step 2: Create `Project/Features/Main/Cart/CartViewModel.swift`**

```swift
import Foundation
import Combine

final class CartViewModel {
    @Published private(set) var items: [CartItem] = []
    var totalPrice: Int { items.reduce(0) { $0 + $1.subtotal } }
    var isEmpty: Bool { items.isEmpty }

    var onCheckout: (() -> Void)?

    private let cart: CartServicing
    private var cancellables = Set<AnyCancellable>()

    init(cart: CartServicing) {
        self.cart = cart
        cart.itemsPublisher
            .sink { [weak self] items in self?.items = items }
            .store(in: &cancellables)
    }

    func setQuantity(_ quantity: Int, for productId: String) {
        cart.setQuantity(quantity, for: productId)
    }

    func remove(productId: String) {
        cart.remove(productId: productId)
    }

    func checkout() {
        onCheckout?()
    }
}
```

- [ ] **Step 3: Run `xcodegen generate`**

```bash
cd /Users/baha/Desktop/llm-ai-projects/sushi-garden-uikit && xcodegen generate
```

- [ ] **Step 4: Run tests to verify they pass**

Use XcodeBuildMCP `test_sim` with `-only-testing:SushiGardenTests/CartViewModelTests`.
Expected: PASS (9 tests).

- [ ] **Step 5: Commit**

```bash
git add Project/Features/Main/Cart/CartViewModel.swift Tests/Features/Main/Cart/CartViewModelTests.swift
git commit -m "feat: add CartViewModel with reactive cart state and checkout trigger"
```

---

## Task 4: CartViewController (build + smoke test)

**Files:**
- Create: `Project/Features/Main/Cart/CartViewController.swift`
- Create: `Tests/Features/Main/Cart/CartViewControllerTests.swift`

- [ ] **Step 1: Create `Tests/Features/Main/Cart/CartViewControllerTests.swift`**

```swift
import XCTest
@testable import SushiGarden

final class CartViewControllerTests: XCTestCase {
    private func makeSUT() -> CartViewController {
        CartViewController(viewModel: CartViewModel(cart: InMemoryCartService()))
    }

    func test_loadsWithoutCrashing() {
        let sut = makeSUT()
        sut.loadViewIfNeeded()
        XCTAssertNotNil(sut.view)
    }

    func test_viewModel_isExposed() {
        let vm = CartViewModel(cart: InMemoryCartService())
        let sut = CartViewController(viewModel: vm)
        XCTAssertTrue(sut.viewModel === vm)
    }
}
```

- [ ] **Step 2: Create `Project/Features/Main/Cart/CartViewController.swift`**

```swift
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
        let cell = tableView.dequeueReusableCell(
            withIdentifier: CartItemCell.reuseIdentifier, for: indexPath) as! CartItemCell
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
```

- [ ] **Step 3: Run `xcodegen generate`**

```bash
cd /Users/baha/Desktop/llm-ai-projects/sushi-garden-uikit && xcodegen generate
```

- [ ] **Step 4: Run tests to verify they pass**

Use XcodeBuildMCP `test_sim` with `-only-testing:SushiGardenTests/CartViewControllerTests`.
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add Project/Features/Main/Cart/CartViewController.swift Tests/Features/Main/Cart/CartViewControllerTests.swift
git commit -m "feat: add CartViewController with item list, empty state, and checkout footer"
```

---

## Task 5: CheckoutViewModel (TDD)

**Files:**
- Create: `Project/Features/Main/Cart/Checkout/CheckoutViewModel.swift`
- Create: `Tests/Features/Main/Cart/Checkout/CheckoutViewModelTests.swift`

The `Geocoding` protocol is defined in `CheckoutViewModel.swift` and lets tests inject a synchronous mock instead of `CLGeocoder`.

- [ ] **Step 1: Create `Tests/Features/Main/Cart/Checkout/CheckoutViewModelTests.swift`**

```swift
import XCTest
import CoreLocation
import MapKit
@testable import SushiGarden

final class CheckoutViewModelTests: XCTestCase {

    // MARK: - Helpers

    private final class MockGeocoder: Geocoding {
        var stubbedPlacemarks: [CLPlacemark]?
        var stubbedError: Error?
        private(set) var cancelCalled = false

        func reverseGeocodeLocation(_ location: CLLocation,
                                    completionHandler: @escaping ([CLPlacemark]?, Error?) -> Void) {
            completionHandler(stubbedPlacemarks, stubbedError)
        }

        func cancelGeocode() { cancelCalled = true }
    }

    private func makeProduct() -> Product {
        Product(id: "p1", name: "Тест", categoryId: "rolls",
                weightGrams: 200, price: 500, imageName: "", description: "")
    }

    private func makeSUT(
        cart: CartServicing = InMemoryCartService(),
        orders: OrdersServicing = InMemoryOrdersService(),
        geocoder: Geocoding = MockGeocoder()
    ) -> CheckoutViewModel {
        let items = [CartItem(product: makeProduct(), quantity: 2)]
        return CheckoutViewModel(items: items, totalPrice: 1000,
                                 orders: orders, cart: cart, geocoder: geocoder)
    }

    private func successGeocoder() -> MockGeocoder {
        let mock = MockGeocoder()
        mock.stubbedPlacemarks = [MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 55.7, longitude: 37.6))]
        return mock
    }

    private let testLocation = CLLocation(latitude: 55.7558, longitude: 37.6173)

    // MARK: - Tests

    func test_address_initiallyEmpty() {
        XCTAssertTrue(makeSUT().address.isEmpty)
    }

    func test_canPlaceOrder_falseWhenNoAddress() {
        XCTAssertFalse(makeSUT().canPlaceOrder)
    }

    func test_reverseGeocode_onSuccess_setsLastDeliveryAddress() {
        let sut = makeSUT(geocoder: successGeocoder())
        sut.reverseGeocode(location: testLocation)
        XCTAssertNotNil(sut.lastDeliveryAddress)
    }

    func test_reverseGeocode_onSuccess_clearsGeocodingFailed() {
        let mock = MockGeocoder()
        mock.stubbedError = NSError(domain: "test", code: 1)
        let sut = makeSUT(geocoder: mock)
        sut.reverseGeocode(location: testLocation) // first call fails

        let successMock = successGeocoder()
        let sut2 = makeSUT(geocoder: successMock)
        sut2.reverseGeocode(location: testLocation)
        XCTAssertFalse(sut2.geocodingFailed)
    }

    func test_reverseGeocode_onError_setsGeocodingFailed() {
        let mock = MockGeocoder()
        mock.stubbedError = NSError(domain: "test", code: 1)
        let sut = makeSUT(geocoder: mock)
        sut.reverseGeocode(location: testLocation)
        XCTAssertTrue(sut.geocodingFailed)
        XCTAssertNil(sut.lastDeliveryAddress)
    }

    func test_reverseGeocode_onEmptyPlacemarks_setsGeocodingFailed() {
        let mock = MockGeocoder()
        mock.stubbedPlacemarks = []
        let sut = makeSUT(geocoder: mock)
        sut.reverseGeocode(location: testLocation)
        XCTAssertTrue(sut.geocodingFailed)
    }

    func test_reverseGeocode_cancelsPreviousRequest() {
        let mock = successGeocoder()
        let sut = makeSUT(geocoder: mock)
        sut.reverseGeocode(location: testLocation)
        XCTAssertTrue(mock.cancelCalled)
    }

    func test_canPlaceOrder_trueAfterSuccessfulGeocode() {
        let sut = makeSUT(geocoder: successGeocoder())
        sut.reverseGeocode(location: testLocation)
        XCTAssertTrue(sut.canPlaceOrder)
    }

    func test_placeOrder_callsOrdersService() {
        let orders = InMemoryOrdersService()
        let sut = makeSUT(orders: orders, geocoder: successGeocoder())
        sut.reverseGeocode(location: testLocation)
        sut.placeOrder()
        XCTAssertEqual(orders.orders.count, 1)
    }

    func test_placeOrder_ordersServiceReceivesCorrectItems() {
        let orders = InMemoryOrdersService()
        let sut = makeSUT(orders: orders, geocoder: successGeocoder())
        sut.reverseGeocode(location: testLocation)
        sut.placeOrder()
        XCTAssertEqual(orders.orders.first?.items.first?.product.id, "p1")
    }

    func test_placeOrder_clearsCart() {
        let cart = InMemoryCartService()
        cart.add(makeProduct())
        let sut = makeSUT(cart: cart, geocoder: successGeocoder())
        sut.reverseGeocode(location: testLocation)
        sut.placeOrder()
        XCTAssertTrue(cart.items.isEmpty)
    }

    func test_placeOrder_firesOnOrderPlaced() {
        let sut = makeSUT(geocoder: successGeocoder())
        var called = false
        sut.onOrderPlaced = { called = true }
        sut.reverseGeocode(location: testLocation)
        sut.placeOrder()
        XCTAssertTrue(called)
    }

    func test_placeOrder_whenNoAddress_doesNothing() {
        let orders = InMemoryOrdersService()
        let sut = makeSUT(orders: orders)
        sut.placeOrder()
        XCTAssertEqual(orders.orders.count, 0)
    }
}
```

- [ ] **Step 2: Create `Project/Features/Main/Cart/Checkout/CheckoutViewModel.swift`**

```swift
import Foundation
import CoreLocation

// Protocol allows injecting a synchronous mock in tests instead of CLGeocoder.
protocol Geocoding {
    func reverseGeocodeLocation(_ location: CLLocation,
                                completionHandler: @escaping ([CLPlacemark]?, Error?) -> Void)
    func cancelGeocode()
}

extension CLGeocoder: Geocoding {}

final class CheckoutViewModel {
    let items: [CartItem]
    let totalPrice: Int

    @Published private(set) var address: String = ""
    @Published private(set) var geocodingFailed: Bool = false
    private(set) var lastDeliveryAddress: DeliveryAddress?
    var canPlaceOrder: Bool { lastDeliveryAddress != nil }

    var onOrderPlaced: (() -> Void)?

    private let orders: OrdersServicing
    private let cart: CartServicing
    private let geocoder: Geocoding

    init(items: [CartItem], totalPrice: Int,
         orders: OrdersServicing, cart: CartServicing,
         geocoder: Geocoding = CLGeocoder()) {
        self.items = items
        self.totalPrice = totalPrice
        self.orders = orders
        self.cart = cart
        self.geocoder = geocoder
    }

    func reverseGeocode(location: CLLocation) {
        geocoder.cancelGeocode()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self else { return }
            guard error == nil, let placemark = placemarks?.first else {
                self.geocodingFailed = true
                return
            }
            let delivery = DeliveryAddress(
                city: placemark.locality ?? "",
                street: placemark.thoroughfare ?? "",
                building: placemark.subThoroughfare ?? ""
            )
            self.lastDeliveryAddress = delivery
            self.address = delivery.formatted
            self.geocodingFailed = false
        }
    }

    func placeOrder() {
        guard let delivery = lastDeliveryAddress else { return }
        orders.placeOrder(items: items, address: delivery)
        cart.clear()
        onOrderPlaced?()
    }
}
```

- [ ] **Step 3: Run `xcodegen generate`**

```bash
cd /Users/baha/Desktop/llm-ai-projects/sushi-garden-uikit && xcodegen generate
```

- [ ] **Step 4: Run tests to verify they pass**

Use XcodeBuildMCP `test_sim` with `-only-testing:SushiGardenTests/CheckoutViewModelTests`.
Expected: PASS (12 tests).

- [ ] **Step 5: Commit**

```bash
git add Project/Features/Main/Cart/Checkout/CheckoutViewModel.swift Tests/Features/Main/Cart/Checkout/CheckoutViewModelTests.swift
git commit -m "feat: add CheckoutViewModel with CLGeocoder injection and order placement"
```

---

## Task 6: CheckoutViewController (build + smoke test)

**Files:**
- Create: `Project/Features/Main/Cart/Checkout/CheckoutViewController.swift`
- Create: `Tests/Features/Main/Cart/Checkout/CheckoutViewControllerTests.swift`

- [ ] **Step 1: Create `Tests/Features/Main/Cart/Checkout/CheckoutViewControllerTests.swift`**

```swift
import XCTest
@testable import SushiGarden

final class CheckoutViewControllerTests: XCTestCase {
    private func makeSUT() -> CheckoutViewController {
        let items = [CartItem(
            product: Product(id: "p1", name: "Тест", categoryId: "rolls",
                             weightGrams: 200, price: 500, imageName: "", description: ""),
            quantity: 1)]
        let vm = CheckoutViewModel(items: items, totalPrice: 500,
                                   orders: InMemoryOrdersService(),
                                   cart: InMemoryCartService())
        return CheckoutViewController(viewModel: vm)
    }

    func test_loadsWithoutCrashing() {
        let sut = makeSUT()
        sut.loadViewIfNeeded()
        XCTAssertNotNil(sut.view)
    }

    func test_viewModel_isExposed() {
        let items = [CartItem(
            product: Product(id: "p2", name: "Осака", categoryId: "rolls",
                             weightGrams: 275, price: 740, imageName: "", description: ""),
            quantity: 2)]
        let vm = CheckoutViewModel(items: items, totalPrice: 1480,
                                   orders: InMemoryOrdersService(),
                                   cart: InMemoryCartService())
        let sut = CheckoutViewController(viewModel: vm)
        XCTAssertTrue(sut.viewModel === vm)
    }
}
```

- [ ] **Step 2: Create `Project/Features/Main/Cart/Checkout/CheckoutViewController.swift`**

```swift
import UIKit
import MapKit
import Combine

final class CheckoutViewController: UIViewController {
    let viewModel: CheckoutViewModel
    private var cancellables = Set<AnyCancellable>()

    private let mapView = MKMapView()
    private let pin = MKPointAnnotation()
    private let addressLabel = UILabel()
    private let geocodeErrorLabel = UILabel()
    private let summaryLabel = UILabel()
    private let confirmButton = PrimaryButton()

    private static let moscowCoordinate = CLLocationCoordinate2D(
        latitude: 55.7558, longitude: 37.6173)

    init(viewModel: CheckoutViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColor.background
        setupLayout()
        setupMap()
        bindViewModel()
        updateSummary()
    }

    private func setupLayout() {
        mapView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mapView)

        addressLabel.text = "Выберите адрес на карте"
        addressLabel.textColor = AppColor.textPrimary
        addressLabel.font = AppFont.productTitle
        addressLabel.numberOfLines = 2
        addressLabel.translatesAutoresizingMaskIntoConstraints = false

        geocodeErrorLabel.text = "Не удалось определить адрес"
        geocodeErrorLabel.textColor = AppColor.accent
        geocodeErrorLabel.font = AppFont.caption
        geocodeErrorLabel.isHidden = true
        geocodeErrorLabel.translatesAutoresizingMaskIntoConstraints = false

        summaryLabel.textColor = AppColor.textSecondary
        summaryLabel.font = AppFont.caption
        summaryLabel.translatesAutoresizingMaskIntoConstraints = false

        confirmButton.setTitle("Подтвердить заказ", for: .normal)
        confirmButton.isEnabled = false
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)

        let infoStack = UIStackView(
            arrangedSubviews: [addressLabel, geocodeErrorLabel, summaryLabel, confirmButton])
        infoStack.axis = .vertical
        infoStack.spacing = Spacing.m
        infoStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(infoStack)

        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5),

            infoStack.topAnchor.constraint(equalTo: mapView.bottomAnchor, constant: Spacing.m),
            infoStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Spacing.m),
            infoStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.m),
        ])
    }

    private func setupMap() {
        mapView.delegate = self
        let region = MKCoordinateRegion(
            center: Self.moscowCoordinate,
            latitudinalMeters: 5000, longitudinalMeters: 5000)
        mapView.setRegion(region, animated: false)
        pin.coordinate = Self.moscowCoordinate
        pin.isDraggable = true
        mapView.addAnnotation(pin)
    }

    private func bindViewModel() {
        viewModel.$address
            .receive(on: DispatchQueue.main)
            .sink { [weak self] addr in
                guard let self else { return }
                if !addr.isEmpty { addressLabel.text = addr }
                confirmButton.isEnabled = viewModel.canPlaceOrder
            }
            .store(in: &cancellables)

        viewModel.$geocodingFailed
            .receive(on: DispatchQueue.main)
            .sink { [weak self] failed in
                self?.geocodeErrorLabel.isHidden = !failed
            }
            .store(in: &cancellables)
    }

    private func updateSummary() {
        let count = viewModel.items.reduce(0) { $0 + $1.quantity }
        summaryLabel.text = "\(count) товар · \(viewModel.totalPrice) ₽"
    }

    @objc private func confirmTapped() {
        viewModel.placeOrder()
    }
}

extension CheckoutViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView,
                 didChange newState: MKAnnotationView.DragState,
                 fromOldState oldState: MKAnnotationView.DragState) {
        guard newState == .none, let coordinate = view.annotation?.coordinate else { return }
        viewModel.reverseGeocode(
            location: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
    }
}
```

- [ ] **Step 3: Run `xcodegen generate`**

```bash
cd /Users/baha/Desktop/llm-ai-projects/sushi-garden-uikit && xcodegen generate
```

- [ ] **Step 4: Run tests to verify they pass**

Use XcodeBuildMCP `test_sim` with `-only-testing:SushiGardenTests/CheckoutViewControllerTests`.
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add Project/Features/Main/Cart/Checkout/CheckoutViewController.swift Tests/Features/Main/Cart/Checkout/CheckoutViewControllerTests.swift
git commit -m "feat: add CheckoutViewController with interactive MapKit map and order CTA"
```

---

## Task 7: CartCoordinator (TDD)

**Files:**
- Create: `Project/Features/Main/Cart/CartCoordinator.swift`
- Create: `Tests/Features/Main/Cart/CartCoordinatorTests.swift`

- [ ] **Step 1: Create `Tests/Features/Main/Cart/CartCoordinatorTests.swift`**

```swift
import XCTest
@testable import SushiGarden

final class CartCoordinatorTests: XCTestCase {
    private func makeSUT(
        onSwitchToOrders: @escaping () -> Void = {}
    ) -> (CartCoordinator, UINavigationController) {
        let nav = UINavigationController()
        let sut = CartCoordinator(
            navigationController: nav,
            container: AppContainer(),
            onSwitchToOrders: onSwitchToOrders)
        return (sut, nav)
    }

    func test_start_setsCartViewControllerAsRoot() {
        let (sut, nav) = makeSUT()
        sut.start()
        XCTAssertTrue(nav.topViewController is CartViewController)
    }

    func test_onCheckout_pushesCheckoutViewController() {
        let (sut, nav) = makeSUT()
        sut.start()
        let cartVC = nav.topViewController as? CartViewController
        cartVC?.viewModel.checkout()
        XCTAssertTrue(nav.viewControllers.last is CheckoutViewController)
    }

    func test_onOrderPlaced_callsSwitchToOrders() {
        var switched = false
        let (sut, nav) = makeSUT(onSwitchToOrders: { switched = true })
        sut.start()
        let cartVC = nav.topViewController as? CartViewController
        cartVC?.viewModel.checkout()
        let checkoutVC = nav.viewControllers.last as? CheckoutViewController
        checkoutVC?.viewModel.onOrderPlaced?()
        XCTAssertTrue(switched)
    }
}
```

- [ ] **Step 2: Create `Project/Features/Main/Cart/CartCoordinator.swift`**

```swift
import UIKit

final class CartCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []

    let navigationController: UINavigationController
    private let container: AppContainer
    private let onSwitchToOrders: () -> Void

    init(navigationController: UINavigationController = UINavigationController(),
         container: AppContainer,
         onSwitchToOrders: @escaping () -> Void) {
        self.navigationController = navigationController
        self.container = container
        self.onSwitchToOrders = onSwitchToOrders
    }

    func start() {
        let vm = CartViewModel(cart: container.cart)
        vm.onCheckout = { [weak self] in self?.showCheckout() }
        let vc = CartViewController(viewModel: vm)
        navigationController.setViewControllers([vc], animated: false)
    }

    private func showCheckout() {
        let vm = CheckoutViewModel(
            items: container.cart.items,
            totalPrice: container.cart.totalPrice,
            orders: container.orders,
            cart: container.cart)
        vm.onOrderPlaced = { [weak self] in self?.orderPlaced() }
        let vc = CheckoutViewController(viewModel: vm)
        navigationController.pushViewController(vc, animated: true)
    }

    private func orderPlaced() {
        navigationController.popToRootViewController(animated: false)
        onSwitchToOrders()
    }
}
```

- [ ] **Step 3: Run `xcodegen generate`**

```bash
cd /Users/baha/Desktop/llm-ai-projects/sushi-garden-uikit && xcodegen generate
```

- [ ] **Step 4: Run tests to verify they pass**

Use XcodeBuildMCP `test_sim` with `-only-testing:SushiGardenTests/CartCoordinatorTests`.
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add Project/Features/Main/Cart/CartCoordinator.swift Tests/Features/Main/Cart/CartCoordinatorTests.swift
git commit -m "feat: add CartCoordinator wiring cart, checkout, and tab switch on order placed"
```

---

## Task 8: Update MainTabCoordinator to install CartCoordinator (TDD)

**Files:**
- Modify: `Project/Features/Main/MainTabCoordinator.swift`
- Modify: `Tests/Features/Main/MainTabCoordinatorTests.swift`

- [ ] **Step 1: Add 2 new tests to `Tests/Features/Main/MainTabCoordinatorTests.swift`**

Append these two methods inside the existing `MainTabCoordinatorTests` class:

```swift
    func test_start_cartTabIsNavigationController() {
        let sut = makeSUT()
        sut.start()
        XCTAssertTrue(sut.tabBarController.viewControllers?[3] is UINavigationController)
    }

    func test_start_cartTabContainsCartViewController() {
        let sut = makeSUT()
        sut.start()
        let nav = sut.tabBarController.viewControllers?[3] as? UINavigationController
        XCTAssertTrue(nav?.topViewController is CartViewController)
    }
```

- [ ] **Step 2: Run tests to verify they fail**

Use XcodeBuildMCP `test_sim` with `-only-testing:SushiGardenTests/MainTabCoordinatorTests`.
Expected: FAIL — the two new tests fail because tab 3 is still a plain `UIViewController`.

- [ ] **Step 3: Replace `Project/Features/Main/MainTabCoordinator.swift`**

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

        let ordersVC = makePlaceholder(title: "Заказы", systemImage: "list.bullet", tag: 1)
        let promotionsVC = makePlaceholder(title: "Акции", systemImage: "tag", tag: 2)

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

        let profileVC = makePlaceholder(title: "Профиль", systemImage: "person", tag: 4)

        tabBarController.viewControllers = [catalogNav, ordersVC, promotionsVC, cartNav, profileVC]
        tabBarController.tabBar.barTintColor = AppColor.surface
        tabBarController.tabBar.tintColor = AppColor.textPrimary
        tabBarController.tabBar.unselectedItemTintColor = AppColor.inactive

        bindCartBadge()
    }

    private func makePlaceholder(title: String, systemImage: String, tag: Int) -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = AppColor.background
        vc.tabBarItem = UITabBarItem(title: title, image: UIImage(systemName: systemImage), tag: tag)
        return vc
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

- [ ] **Step 4: Run all tests**

Use XcodeBuildMCP `test_sim` (no filter — full suite).
Expected: ALL tests PASS. Total should be ~110+ tests.

If `test_cartBadge_updatesWhenItemAddedToCart` or `test_cartBadge_clearsWhenCartIsEmpty` fail, the badge is now updating `cartNav.tabBarItem` instead of the old plain VC's tabBarItem — that is correct. The tests access `sut.tabBarController.viewControllers?[3].tabBarItem.badgeValue`, which still refers to `cartNav.tabBarItem`. They should still pass.

- [ ] **Step 5: Commit**

```bash
git add Project/Features/Main/MainTabCoordinator.swift Tests/Features/Main/MainTabCoordinatorTests.swift
git commit -m "feat: install CartCoordinator in MainTabCoordinator replacing cart placeholder"
```

---

## Phase 4 done-when

- Full test suite is green.
- `xcodebuild build` succeeds for iOS 17 simulator.
- Logging in → Cart tab shows "Корзина пуста" with hidden footer.
- Adding products from Catalog → cart badge updates on tab 3 → Cart tab shows items with steppers.
- Swipe on a row → item removed.
- Stepper change in cart → subtotal updates.
- "Оформить заказ" → Checkout screen with Moscow map and a draggable pin.
- Dragging pin → address label updates (after drag ends, geocoder returns).
- "Подтвердить заказ" enabled only after address set; tapping it clears cart and switches to tab 1 (Заказы placeholder).
