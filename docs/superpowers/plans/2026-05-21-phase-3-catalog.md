# Sushi Garden (UIKit) — Phase 3: Catalog + Detail + Tab Shell — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the `MainTabCoordinator` tab shell, the Catalog screen (category tabs + 2-column product grid), and the Product Detail screen; wire `AppCoordinator` to install the tab bar on auth success.

**Architecture:** `MainTabCoordinator` owns a `UITabBarController` with five tabs; Tab 1 is a fully live `CatalogCoordinator` (nav stack: Catalog → push Detail), tabs 2–5 are placeholder `UIViewController`s (replaced in later phases). `CatalogViewController` uses a compositional `UICollectionView` with a diffable data source: Section 0 = horizontally-scrolling category tabs, Section 1 = 2-column product grid. `CatalogViewModel` holds `@Published` state; the VC sinks to re-render. `AppCoordinator.setRoot(isAuthenticated: true)` now installs `MainTabCoordinator` instead of the old `MainPlaceholderViewController` stub.

**Tech Stack:** Swift 5.9, iOS 17, UIKit + Combine, `UICollectionViewCompositionalLayout`, `UICollectionViewDiffableDataSource`, `NSDiffableDataSourceSnapshot`, XCTest.

---

## Phase roadmap context

| Phase | Status |
|---|---|
| 1. Foundation & App Skeleton | ✅ Complete |
| 2. Auth flow | ✅ Complete |
| **3. Catalog + Detail + Tab shell** | **← this plan** |
| 4. Cart + Checkout + Orders | next |
| 5. Orders / Promotions / Profile | later |

---

## Existing infrastructure (do not re-implement)

- `Project/DesignSystem/Colors.swift` — `AppColor.*`
- `Project/DesignSystem/Typography.swift` — `AppFont.*` (Sen, sizes listed in file)
- `Project/DesignSystem/Spacing.swift` — `Spacing.xs=4, .s=8, .m=16, .l=24, .xl=32, .cardRadius=12`
- `Project/DesignSystem/PrimaryButton.swift` — red 52-pt CTA button
- `Project/Services/Catalog/CatalogServicing.swift` — `CatalogServicing` protocol + `InMemoryCatalogService` (5 categories, 4 products in "rolls")
- `Project/Services/Cart/CartServicing.swift` — `CartServicing` protocol + `InMemoryCartService` (`itemsPublisher: AnyPublisher<[CartItem], Never>`, `add(_:)`, `totalCount`)
- `Project/Models/Category.swift`, `Product.swift`, `CartItem.swift` — all defined
- `Project/Core/DI/AppContainer.swift` — holds `catalog: CatalogServicing`, `cart: CartServicing`
- `Project/Core/Coordinator/Coordinator.swift` — `Coordinator` protocol, `addChild`/`removeChild`
- `Project/Core/Coordinator/AppCoordinator.swift` — subscribes to `isAuthenticatedPublisher`; currently installs `MainPlaceholderViewController` on auth success (replaced in Task 10)
- `Project/Placeholders/MainPlaceholderViewController.swift` — deleted in Task 10

---

## File structure introduced in Phase 3

```
Project/
  DesignSystem/
    QuantityStepper.swift        +/- counter, manages count ≥ 1
    CategoryTabCell.swift        UICollectionViewCell: pill tab, selected/unselected state
    ProductCell.swift            UICollectionViewCell: image, name, weight, price, + button
  Features/
    Main/
      MainTabCoordinator.swift   UITabBarController shell; CatalogCoordinator live; 4 placeholder tabs; cart badge
      Catalog/
        CatalogCoordinator.swift Catalog root → push ProductDetail
        CatalogViewModel.swift   @Published selectedCategoryId + displayedProducts
        CatalogViewController.swift compositional UICollectionView + diffable data source
        ProductDetail/
          ProductDetailViewModel.swift  product + addToCart(quantity:)
          ProductDetailViewController.swift hero + QuantityStepper + CTA

Tests/
  DesignSystem/
    QuantityStepperTests.swift
    CategoryTabCellTests.swift
    ProductCellTests.swift
  Features/
    Main/
      MainTabCoordinatorTests.swift
      Catalog/
        CatalogViewModelTests.swift
        CatalogViewControllerTests.swift
        CatalogCoordinatorTests.swift
        ProductDetailViewModelTests.swift
        ProductDetailViewControllerTests.swift
```

Modified:
- `Project/Core/Coordinator/AppCoordinator.swift`
- `Tests/Core/AppCoordinatorTests.swift`

Deleted:
- `Project/Placeholders/MainPlaceholderViewController.swift`

---

## Task 1: QuantityStepper design system component (TDD)

**Files:**
- Create: `Project/DesignSystem/QuantityStepper.swift`
- Test: `Tests/DesignSystem/QuantityStepperTests.swift`

- [ ] **Step 1: Write the failing test**

Create `Tests/DesignSystem/QuantityStepperTests.swift`:

```swift
import XCTest
@testable import SushiGarden

final class QuantityStepperTests: XCTestCase {
    func test_initialCount_isOne() {
        let sut = QuantityStepper()
        XCTAssertEqual(sut.count, 1)
    }

    func test_increment_increasesCount() {
        let sut = QuantityStepper()
        sut.increment()
        XCTAssertEqual(sut.count, 2)
    }

    func test_decrement_decreasesCount() {
        let sut = QuantityStepper()
        sut.increment()
        sut.decrement()
        XCTAssertEqual(sut.count, 1)
    }

    func test_decrement_atOne_doesNothing() {
        let sut = QuantityStepper()
        sut.decrement()
        XCTAssertEqual(sut.count, 1)
    }

    func test_onCountChanged_calledOnIncrement() {
        let sut = QuantityStepper()
        var received: Int?
        sut.onCountChanged = { received = $0 }
        sut.increment()
        XCTAssertEqual(received, 2)
    }

    func test_onCountChanged_calledOnDecrement() {
        let sut = QuantityStepper()
        sut.increment() // count = 2
        var received: Int?
        sut.onCountChanged = { received = $0 }
        sut.decrement()
        XCTAssertEqual(received, 1)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Use XcodeBuildMCP `test_sim` with `-only-testing:SushiGardenTests/QuantityStepperTests`.
Expected: FAIL — `QuantityStepper` undefined.

- [ ] **Step 3: Write `Project/DesignSystem/QuantityStepper.swift`**

```swift
import UIKit

final class QuantityStepper: UIView {
    private(set) var count: Int = 1
    var onCountChanged: ((Int) -> Void)?

    private let decrementButton = UIButton(type: .system)
    private let countLabel = UILabel()
    private let incrementButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func increment() {
        count += 1
        countLabel.text = "\(count)"
        onCountChanged?(count)
    }

    func decrement() {
        guard count > 1 else { return }
        count -= 1
        countLabel.text = "\(count)"
        onCountChanged?(count)
    }

    private func setup() {
        backgroundColor = AppColor.elevated
        layer.cornerRadius = Spacing.cardRadius
        translatesAutoresizingMaskIntoConstraints = false

        decrementButton.setTitle("−", for: .normal)
        decrementButton.setTitleColor(AppColor.textPrimary, for: .normal)
        decrementButton.titleLabel?.font = AppFont.price
        decrementButton.translatesAutoresizingMaskIntoConstraints = false
        decrementButton.addTarget(self, action: #selector(decrementTapped), for: .touchUpInside)

        countLabel.text = "1"
        countLabel.textColor = AppColor.textPrimary
        countLabel.font = AppFont.weight
        countLabel.textAlignment = .center
        countLabel.translatesAutoresizingMaskIntoConstraints = false

        incrementButton.setTitle("+", for: .normal)
        incrementButton.setTitleColor(AppColor.textPrimary, for: .normal)
        incrementButton.titleLabel?.font = AppFont.price
        incrementButton.translatesAutoresizingMaskIntoConstraints = false
        incrementButton.addTarget(self, action: #selector(incrementTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [decrementButton, countLabel, incrementButton])
        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 44),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Spacing.m),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.m),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    @objc private func decrementTapped() { decrement() }
    @objc private func incrementTapped() { increment() }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Use XcodeBuildMCP `test_sim` with `-only-testing:SushiGardenTests/QuantityStepperTests`.
Expected: PASS (6 tests).

- [ ] **Step 5: Commit**

```bash
git add Project/DesignSystem/QuantityStepper.swift Tests/DesignSystem/QuantityStepperTests.swift
git commit -m "feat: add QuantityStepper design system component"
```

---

## Task 2: CategoryTabCell (TDD)

**Files:**
- Create: `Project/DesignSystem/CategoryTabCell.swift`
- Test: `Tests/DesignSystem/CategoryTabCellTests.swift`

- [ ] **Step 1: Write the failing test**

Create `Tests/DesignSystem/CategoryTabCellTests.swift`:

```swift
import XCTest
@testable import SushiGarden

final class CategoryTabCellTests: XCTestCase {
    func test_configure_setsTitle() {
        let sut = CategoryTabCell()
        sut.configure(name: "Роллы", isSelected: false)
        XCTAssertEqual(sut.titleLabel.text, "Роллы")
    }

    func test_configure_selected_usesAccentBackground() {
        let sut = CategoryTabCell()
        sut.configure(name: "Роллы", isSelected: true)
        XCTAssertEqual(sut.contentView.backgroundColor, AppColor.accent)
    }

    func test_configure_unselected_usesElevatedBackground() {
        let sut = CategoryTabCell()
        sut.configure(name: "Роллы", isSelected: false)
        XCTAssertEqual(sut.contentView.backgroundColor, AppColor.elevated)
    }
}
```

Note: `titleLabel` must be `internal` (not `private`) for tests to access it.

- [ ] **Step 2: Run test to verify it fails**

Use XcodeBuildMCP `test_sim` with `-only-testing:SushiGardenTests/CategoryTabCellTests`.
Expected: FAIL — `CategoryTabCell` undefined.

- [ ] **Step 3: Write `Project/DesignSystem/CategoryTabCell.swift`**

```swift
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
```

- [ ] **Step 4: Run tests to verify they pass**

Use XcodeBuildMCP `test_sim` with `-only-testing:SushiGardenTests/CategoryTabCellTests`.
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add Project/DesignSystem/CategoryTabCell.swift Tests/DesignSystem/CategoryTabCellTests.swift
git commit -m "feat: add CategoryTabCell design system component"
```

---

## Task 3: ProductCell (TDD)

**Files:**
- Create: `Project/DesignSystem/ProductCell.swift`
- Test: `Tests/DesignSystem/ProductCellTests.swift`

- [ ] **Step 1: Write the failing test**

Create `Tests/DesignSystem/ProductCellTests.swift`:

```swift
import XCTest
@testable import SushiGarden

final class ProductCellTests: XCTestCase {
    private func makeProduct() -> Product {
        Product(id: "p1", name: "Хикари", categoryId: "rolls",
                weightGrams: 255, price: 620, imageName: "hikari", description: "Test roll")
    }

    func test_configure_setsNameLabel() {
        let sut = ProductCell()
        sut.configure(with: makeProduct())
        XCTAssertEqual(sut.nameLabel.text, "Хикари")
    }

    func test_configure_setsWeightLabel_withGramsUnit() {
        let sut = ProductCell()
        sut.configure(with: makeProduct())
        XCTAssertEqual(sut.weightLabel.text, "255 г")
    }

    func test_configure_setsPriceLabel_withRublesUnit() {
        let sut = ProductCell()
        sut.configure(with: makeProduct())
        XCTAssertEqual(sut.priceLabel.text, "620 ₽")
    }

    func test_onAddTapped_isCalled() {
        let sut = ProductCell()
        sut.configure(with: makeProduct())
        var called = false
        sut.onAddTapped = { called = true }
        sut.simulateAddTap()
        XCTAssertTrue(called)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Use XcodeBuildMCP `test_sim` with `-only-testing:SushiGardenTests/ProductCellTests`.
Expected: FAIL — `ProductCell` undefined.

- [ ] **Step 3: Write `Project/DesignSystem/ProductCell.swift`**

```swift
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
```

- [ ] **Step 4: Run tests to verify they pass**

Use XcodeBuildMCP `test_sim` with `-only-testing:SushiGardenTests/ProductCellTests`.
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add Project/DesignSystem/ProductCell.swift Tests/DesignSystem/ProductCellTests.swift
git commit -m "feat: add ProductCell design system component"
```

---

## Task 4: CatalogViewModel (TDD)

**Files:**
- Create: `Project/Features/Main/Catalog/CatalogViewModel.swift`
- Test: `Tests/Features/Main/Catalog/CatalogViewModelTests.swift`

- [ ] **Step 1: Write the failing test**

Create `Tests/Features/Main/Catalog/CatalogViewModelTests.swift`:

```swift
import XCTest
import Combine
@testable import SushiGarden

final class CatalogViewModelTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()

    override func tearDown() {
        cancellables = []
        super.tearDown()
    }

    func test_categories_returnsAllCategories() {
        let sut = CatalogViewModel(catalog: InMemoryCatalogService(), cart: InMemoryCartService())
        XCTAssertEqual(sut.categories.count, InMemoryCatalogService().categories().count)
    }

    func test_initialSelectedCategoryId_isFirstCategoryId() {
        let service = InMemoryCatalogService()
        let sut = CatalogViewModel(catalog: service, cart: InMemoryCartService())
        XCTAssertEqual(sut.selectedCategoryId, service.categories().first?.id)
    }

    func test_displayedProducts_matchInitialCategory() {
        let service = InMemoryCatalogService()
        let sut = CatalogViewModel(catalog: service, cart: InMemoryCartService())
        let expected = service.products(in: service.categories().first!.id)
        XCTAssertEqual(sut.displayedProducts, expected)
    }

    func test_selectCategory_updatesSelectedCategoryId() {
        let service = InMemoryCatalogService()
        let sut = CatalogViewModel(catalog: service, cart: InMemoryCartService())
        let target = service.categories()[1]
        sut.selectCategory(target.id)
        XCTAssertEqual(sut.selectedCategoryId, target.id)
    }

    func test_selectCategory_updatesDisplayedProducts() {
        let service = InMemoryCatalogService()
        let sut = CatalogViewModel(catalog: service, cart: InMemoryCartService())
        let target = service.categories().first(where: { $0.id == "rolls" })!
        sut.selectCategory(target.id)
        let expected = service.products(in: "rolls")
        XCTAssertEqual(sut.displayedProducts, expected)
    }

    func test_addToCart_addsProductToCart() {
        let cart = InMemoryCartService()
        let catalog = InMemoryCatalogService()
        let sut = CatalogViewModel(catalog: catalog, cart: cart)
        let product = catalog.allProducts().first!
        sut.addToCart(product)
        XCTAssertEqual(cart.totalCount, 1)
    }

    func test_selectProduct_callsOnSelectProduct() {
        let sut = CatalogViewModel(catalog: InMemoryCatalogService(), cart: InMemoryCartService())
        let product = InMemoryCatalogService().allProducts().first!
        var received: Product?
        sut.onSelectProduct = { received = $0 }
        sut.selectProduct(product)
        XCTAssertEqual(received, product)
    }

    func test_selectCategory_publishesUpdatedDisplayedProducts() {
        let service = InMemoryCatalogService()
        let sut = CatalogViewModel(catalog: service, cart: InMemoryCartService())
        var publishedProducts: [[Product]] = []
        sut.$displayedProducts
            .dropFirst()
            .sink { publishedProducts.append($0) }
            .store(in: &cancellables)
        let rollsId = service.categories().first(where: { $0.id == "rolls" })!.id
        sut.selectCategory(rollsId)
        XCTAssertEqual(publishedProducts.count, 1)
        XCTAssertEqual(publishedProducts[0], service.products(in: rollsId))
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Use XcodeBuildMCP `test_sim` with `-only-testing:SushiGardenTests/CatalogViewModelTests`.
Expected: FAIL — `CatalogViewModel` undefined.

- [ ] **Step 3: Write `Project/Features/Main/Catalog/CatalogViewModel.swift`**

```swift
import Foundation
import Combine

final class CatalogViewModel {
    @Published private(set) var selectedCategoryId: String
    @Published private(set) var displayedProducts: [Product]

    var onSelectProduct: ((Product) -> Void)?

    private let catalog: CatalogServicing
    private let cart: CartServicing

    init(catalog: CatalogServicing, cart: CartServicing) {
        self.catalog = catalog
        self.cart = cart
        let firstId = catalog.categories().first?.id ?? ""
        self.selectedCategoryId = firstId
        self.displayedProducts = catalog.products(in: firstId)
    }

    var categories: [Category] { catalog.categories() }

    func selectCategory(_ id: String) {
        selectedCategoryId = id
        displayedProducts = catalog.products(in: id)
    }

    func addToCart(_ product: Product) {
        cart.add(product)
    }

    func selectProduct(_ product: Product) {
        onSelectProduct?(product)
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Use XcodeBuildMCP `test_sim` with `-only-testing:SushiGardenTests/CatalogViewModelTests`.
Expected: PASS (8 tests).

- [ ] **Step 5: Commit**

```bash
git add Project/Features/Main/Catalog/CatalogViewModel.swift Tests/Features/Main/Catalog/CatalogViewModelTests.swift
git commit -m "feat: add CatalogViewModel with category selection and cart integration"
```

---

## Task 5: CatalogViewController (build + smoke test)

**Files:**
- Create: `Project/Features/Main/Catalog/CatalogViewController.swift`
- Test: `Tests/Features/Main/Catalog/CatalogViewControllerTests.swift`

- [ ] **Step 1: Write the failing test**

Create `Tests/Features/Main/Catalog/CatalogViewControllerTests.swift`:

```swift
import XCTest
@testable import SushiGarden

final class CatalogViewControllerTests: XCTestCase {
    private func makeSUT() -> CatalogViewController {
        let vm = CatalogViewModel(catalog: InMemoryCatalogService(), cart: InMemoryCartService())
        return CatalogViewController(viewModel: vm)
    }

    func test_loadsWithoutCrashing() {
        let sut = makeSUT()
        sut.loadViewIfNeeded()
        XCTAssertNotNil(sut.view)
    }

    func test_viewModel_isExposed() {
        let vm = CatalogViewModel(catalog: InMemoryCatalogService(), cart: InMemoryCartService())
        let sut = CatalogViewController(viewModel: vm)
        XCTAssertTrue(sut.viewModel === vm)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Use XcodeBuildMCP `test_sim` with `-only-testing:SushiGardenTests/CatalogViewControllerTests`.
Expected: FAIL — `CatalogViewController` undefined.

- [ ] **Step 3: Write `Project/Features/Main/Catalog/CatalogViewController.swift`**

```swift
import UIKit
import Combine

final class CatalogViewController: UIViewController {
    let viewModel: CatalogViewModel
    private var cancellables = Set<AnyCancellable>()
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>!

    enum Section: Int, CaseIterable {
        case categories, products
    }

    enum Item: Hashable {
        case category(Category)
        case product(Product)
    }

    init(viewModel: CatalogViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColor.background
        setupCollectionView()
        configureDataSource()
        bindViewModel()
    }

    // MARK: - Layout

    private func makeLayout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { sectionIndex, _ in
            switch Section(rawValue: sectionIndex)! {
            case .categories:
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .estimated(90),
                    heightDimension: .absolute(40))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .estimated(90),
                    heightDimension: .absolute(40))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = .continuous
                section.interGroupSpacing = Spacing.s
                section.contentInsets = NSDirectionalEdgeInsets(
                    top: Spacing.m, leading: Spacing.m,
                    bottom: Spacing.m, trailing: Spacing.m)
                return section

            case .products:
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(0.5),
                    heightDimension: .absolute(230))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(
                    top: 0, leading: Spacing.s / 2,
                    bottom: 0, trailing: Spacing.s / 2)
                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(230))
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: groupSize, subitems: [item, item])
                let section = NSCollectionLayoutSection(group: group)
                section.interGroupSpacing = Spacing.s
                section.contentInsets = NSDirectionalEdgeInsets(
                    top: 0, leading: Spacing.s / 2,
                    bottom: Spacing.m, trailing: Spacing.s / 2)
                return section
            }
        }
    }

    // MARK: - Setup

    private func setupCollectionView() {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
        collectionView.backgroundColor = AppColor.background
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = self
        collectionView.register(CategoryTabCell.self,
                                forCellWithReuseIdentifier: CategoryTabCell.reuseIdentifier)
        collectionView.register(ProductCell.self,
                                forCellWithReuseIdentifier: ProductCell.reuseIdentifier)
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Section, Item>(
            collectionView: collectionView
        ) { [weak self] collectionView, indexPath, item in
            guard let self else { return UICollectionViewCell() }
            switch item {
            case .category(let category):
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: CategoryTabCell.reuseIdentifier,
                    for: indexPath) as! CategoryTabCell
                cell.configure(name: category.name,
                               isSelected: category.id == self.viewModel.selectedCategoryId)
                return cell

            case .product(let product):
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: ProductCell.reuseIdentifier,
                    for: indexPath) as! ProductCell
                cell.configure(with: product)
                cell.onAddTapped = { [weak self] in self?.viewModel.addToCart(product) }
                return cell
            }
        }
    }

    // MARK: - Binding

    private func bindViewModel() {
        viewModel.$displayedProducts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.applySnapshot() }
            .store(in: &cancellables)
    }

    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections(Section.allCases)
        let categoryItems = viewModel.categories.map { Item.category($0) }
        let productItems = viewModel.displayedProducts.map { Item.product($0) }
        snapshot.appendItems(categoryItems, toSection: .categories)
        snapshot.appendItems(productItems, toSection: .products)
        // Reconfigure category cells so selected state reflects current selection
        snapshot.reconfigureItems(categoryItems)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}

// MARK: - UICollectionViewDelegate

extension CatalogViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        switch item {
        case .category(let category):
            viewModel.selectCategory(category.id)
        case .product(let product):
            viewModel.selectProduct(product)
        }
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Use XcodeBuildMCP `test_sim` with `-only-testing:SushiGardenTests/CatalogViewControllerTests`.
Expected: PASS (2 tests).

- [ ] **Step 5: Build to confirm no compile errors**

Use XcodeBuildMCP `build_sim`.
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 6: Commit**

```bash
git add Project/Features/Main/Catalog/CatalogViewController.swift Tests/Features/Main/Catalog/CatalogViewControllerTests.swift
git commit -m "feat: add CatalogViewController with compositional collection view and diffable data source"
```

---

## Task 6: ProductDetailViewModel (TDD)

**Files:**
- Create: `Project/Features/Main/Catalog/ProductDetail/ProductDetailViewModel.swift`
- Test: `Tests/Features/Main/Catalog/ProductDetailViewModelTests.swift`

- [ ] **Step 1: Write the failing test**

Create `Tests/Features/Main/Catalog/ProductDetailViewModelTests.swift`:

```swift
import XCTest
@testable import SushiGarden

final class ProductDetailViewModelTests: XCTestCase {
    private func makeProduct() -> Product {
        Product(id: "p1", name: "Хикари", categoryId: "rolls",
                weightGrams: 255, price: 620, imageName: "hikari", description: "Light roll")
    }

    func test_product_isExposed() {
        let product = makeProduct()
        let sut = ProductDetailViewModel(product: product, cart: InMemoryCartService())
        XCTAssertEqual(sut.product, product)
    }

    func test_addToCart_withQuantityOne_addsOneItem() {
        let cart = InMemoryCartService()
        let sut = ProductDetailViewModel(product: makeProduct(), cart: cart)
        sut.addToCart(quantity: 1)
        XCTAssertEqual(cart.totalCount, 1)
    }

    func test_addToCart_withQuantityThree_addsThreeItems() {
        let cart = InMemoryCartService()
        let sut = ProductDetailViewModel(product: makeProduct(), cart: cart)
        sut.addToCart(quantity: 3)
        XCTAssertEqual(cart.totalCount, 3)
    }

    func test_addToCart_callsOnAddedToCart() {
        let sut = ProductDetailViewModel(product: makeProduct(), cart: InMemoryCartService())
        var called = false
        sut.onAddedToCart = { called = true }
        sut.addToCart(quantity: 1)
        XCTAssertTrue(called)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Use XcodeBuildMCP `test_sim` with `-only-testing:SushiGardenTests/ProductDetailViewModelTests`.
Expected: FAIL — `ProductDetailViewModel` undefined.

- [ ] **Step 3: Write `Project/Features/Main/Catalog/ProductDetail/ProductDetailViewModel.swift`**

```swift
import Foundation

final class ProductDetailViewModel {
    let product: Product
    var onAddedToCart: (() -> Void)?

    private let cart: CartServicing

    init(product: Product, cart: CartServicing) {
        self.product = product
        self.cart = cart
    }

    func addToCart(quantity: Int) {
        for _ in 0..<quantity {
            cart.add(product)
        }
        onAddedToCart?()
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Use XcodeBuildMCP `test_sim` with `-only-testing:SushiGardenTests/ProductDetailViewModelTests`.
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add Project/Features/Main/Catalog/ProductDetail/ProductDetailViewModel.swift Tests/Features/Main/Catalog/ProductDetailViewModelTests.swift
git commit -m "feat: add ProductDetailViewModel with quantity-aware addToCart"
```

---

## Task 7: ProductDetailViewController (build + smoke test)

**Files:**
- Create: `Project/Features/Main/Catalog/ProductDetail/ProductDetailViewController.swift`
- Test: `Tests/Features/Main/Catalog/ProductDetailViewControllerTests.swift`

- [ ] **Step 1: Write the failing test**

Create `Tests/Features/Main/Catalog/ProductDetailViewControllerTests.swift`:

```swift
import XCTest
@testable import SushiGarden

final class ProductDetailViewControllerTests: XCTestCase {
    private func makeSUT() -> ProductDetailViewController {
        let product = Product(id: "p1", name: "Хикари", categoryId: "rolls",
                              weightGrams: 255, price: 620, imageName: "hikari", description: "")
        let vm = ProductDetailViewModel(product: product, cart: InMemoryCartService())
        return ProductDetailViewController(viewModel: vm)
    }

    func test_loadsWithoutCrashing() {
        let sut = makeSUT()
        sut.loadViewIfNeeded()
        XCTAssertNotNil(sut.view)
    }

    func test_viewModel_isExposed() {
        let product = Product(id: "p2", name: "Осака", categoryId: "rolls",
                              weightGrams: 275, price: 740, imageName: "osaka", description: "")
        let vm = ProductDetailViewModel(product: product, cart: InMemoryCartService())
        let sut = ProductDetailViewController(viewModel: vm)
        XCTAssertTrue(sut.viewModel === vm)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Use XcodeBuildMCP `test_sim` with `-only-testing:SushiGardenTests/ProductDetailViewControllerTests`.
Expected: FAIL — `ProductDetailViewController` undefined.

- [ ] **Step 3: Write `Project/Features/Main/Catalog/ProductDetail/ProductDetailViewController.swift`**

```swift
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
    }

    @objc private func addToCartTapped() {
        viewModel.addToCart(quantity: stepper.count)
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Use XcodeBuildMCP `test_sim` with `-only-testing:SushiGardenTests/ProductDetailViewControllerTests`.
Expected: PASS (2 tests).

- [ ] **Step 5: Build to confirm no compile errors**

Use XcodeBuildMCP `build_sim`.
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 6: Commit**

```bash
git add Project/Features/Main/Catalog/ProductDetail/ProductDetailViewController.swift Tests/Features/Main/Catalog/ProductDetailViewControllerTests.swift
git commit -m "feat: add ProductDetailViewController with hero image and quantity stepper"
```

---

## Task 8: CatalogCoordinator (TDD)

**Files:**
- Create: `Project/Features/Main/Catalog/CatalogCoordinator.swift`
- Test: `Tests/Features/Main/Catalog/CatalogCoordinatorTests.swift`

- [ ] **Step 1: Write the failing test**

Create `Tests/Features/Main/Catalog/CatalogCoordinatorTests.swift`:

```swift
import XCTest
@testable import SushiGarden

final class CatalogCoordinatorTests: XCTestCase {
    private func makeSUT() -> (CatalogCoordinator, UINavigationController) {
        let nav = UINavigationController()
        let container = AppContainer()
        let sut = CatalogCoordinator(navigationController: nav, container: container)
        return (sut, nav)
    }

    func test_start_setsCatalogViewControllerAsRoot() {
        let (sut, nav) = makeSUT()
        sut.start()
        XCTAssertTrue(nav.topViewController is CatalogViewController)
    }

    func test_afterSelectProduct_pushesProductDetailViewController() {
        let (sut, nav) = makeSUT()
        sut.start()
        let catalogVC = nav.topViewController as? CatalogViewController
        let product = InMemoryCatalogService().allProducts().first!
        catalogVC?.viewModel.selectProduct(product)
        XCTAssertTrue(nav.viewControllers.last is ProductDetailViewController)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Use XcodeBuildMCP `test_sim` with `-only-testing:SushiGardenTests/CatalogCoordinatorTests`.
Expected: FAIL — `CatalogCoordinator` undefined.

- [ ] **Step 3: Write `Project/Features/Main/Catalog/CatalogCoordinator.swift`**

```swift
import UIKit

final class CatalogCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []

    let navigationController: UINavigationController
    private let container: AppContainer

    init(navigationController: UINavigationController = UINavigationController(),
         container: AppContainer) {
        self.navigationController = navigationController
        self.container = container
    }

    func start() {
        let vm = CatalogViewModel(catalog: container.catalog, cart: container.cart)
        vm.onSelectProduct = { [weak self] product in self?.showDetail(product) }
        let vc = CatalogViewController(viewModel: vm)
        navigationController.setViewControllers([vc], animated: false)
    }

    private func showDetail(_ product: Product) {
        let vm = ProductDetailViewModel(product: product, cart: container.cart)
        vm.onAddedToCart = { [weak self] in
            self?.navigationController.popViewController(animated: true)
        }
        let vc = ProductDetailViewController(viewModel: vm)
        navigationController.pushViewController(vc, animated: true)
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Use XcodeBuildMCP `test_sim` with `-only-testing:SushiGardenTests/CatalogCoordinatorTests`.
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add Project/Features/Main/Catalog/CatalogCoordinator.swift Tests/Features/Main/Catalog/CatalogCoordinatorTests.swift
git commit -m "feat: add CatalogCoordinator routing catalog to product detail"
```

---

## Task 9: MainTabCoordinator (TDD)

**Files:**
- Create: `Project/Features/Main/MainTabCoordinator.swift`
- Test: `Tests/Features/Main/MainTabCoordinatorTests.swift`

- [ ] **Step 1: Write the failing test**

Create `Tests/Features/Main/MainTabCoordinatorTests.swift`:

```swift
import XCTest
@testable import SushiGarden

final class MainTabCoordinatorTests: XCTestCase {
    private func makeSUT() -> MainTabCoordinator {
        MainTabCoordinator(container: AppContainer())
    }

    func test_start_creates5Tabs() {
        let sut = makeSUT()
        sut.start()
        XCTAssertEqual(sut.tabBarController.viewControllers?.count, 5)
    }

    func test_start_firstTabIsNavigationController() {
        let sut = makeSUT()
        sut.start()
        XCTAssertTrue(sut.tabBarController.viewControllers?.first is UINavigationController)
    }

    func test_start_firstTabContainsCatalogViewController() {
        let sut = makeSUT()
        sut.start()
        let nav = sut.tabBarController.viewControllers?.first as? UINavigationController
        XCTAssertTrue(nav?.topViewController is CatalogViewController)
    }

    func test_cartBadge_updatesWhenItemAddedToCart() {
        let cart = InMemoryCartService()
        let container = AppContainer(cart: cart)
        let sut = MainTabCoordinator(container: container)
        sut.start()
        let product = InMemoryCatalogService().allProducts().first!
        cart.add(product)
        // Cart is tab index 3
        XCTAssertEqual(sut.tabBarController.viewControllers?[3].tabBarItem.badgeValue, "1")
    }

    func test_cartBadge_clearsWhenCartIsEmpty() {
        let cart = InMemoryCartService()
        let container = AppContainer(cart: cart)
        let sut = MainTabCoordinator(container: container)
        sut.start()
        let product = InMemoryCatalogService().allProducts().first!
        cart.add(product)
        cart.clear()
        XCTAssertNil(sut.tabBarController.viewControllers?[3].tabBarItem.badgeValue)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Use XcodeBuildMCP `test_sim` with `-only-testing:SushiGardenTests/MainTabCoordinatorTests`.
Expected: FAIL — `MainTabCoordinator` undefined.

- [ ] **Step 3: Write `Project/Features/Main/MainTabCoordinator.swift`**

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
        catalogNav.tabBarItem = UITabBarItem(title: "Каталог",
                                             image: UIImage(systemName: "fork.knife"), tag: 0)

        let ordersVC = makePlaceholder(title: "Заказы", systemImage: "list.bullet", tag: 1)
        let promotionsVC = makePlaceholder(title: "Акции", systemImage: "tag", tag: 2)
        let cartVC = makePlaceholder(title: "Корзина", systemImage: "bag", tag: 3)
        let profileVC = makePlaceholder(title: "Профиль", systemImage: "person", tag: 4)

        tabBarController.viewControllers = [catalogNav, ordersVC, promotionsVC, cartVC, profileVC]
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

Note: `bindCartBadge()` does NOT use `.receive(on: DispatchQueue.main)`. `InMemoryCartService` uses a `CurrentValueSubject` that delivers synchronously on the calling thread (always main in tests and in the app). Omitting `.receive(on:)` keeps delivery synchronous — critical for the badge tests to pass without `XCTestExpectation`.

- [ ] **Step 4: Run tests to verify they pass**

Use XcodeBuildMCP `test_sim` with `-only-testing:SushiGardenTests/MainTabCoordinatorTests`.
Expected: PASS (5 tests).

- [ ] **Step 5: Commit**

```bash
git add Project/Features/Main/MainTabCoordinator.swift Tests/Features/Main/MainTabCoordinatorTests.swift
git commit -m "feat: add MainTabCoordinator with catalog tab and reactive cart badge"
```

---

## Task 10: Update AppCoordinator + delete MainPlaceholderViewController (TDD)

**Files:**
- Modify: `Project/Core/Coordinator/AppCoordinator.swift`
- Modify: `Tests/Core/AppCoordinatorTests.swift`
- Delete: `Project/Placeholders/MainPlaceholderViewController.swift`

- [ ] **Step 1: Update `Tests/Core/AppCoordinatorTests.swift`**

Replace the entire file:

```swift
import XCTest
@testable import SushiGarden

final class AppCoordinatorTests: XCTestCase {
    func test_start_whenUnauthenticated_setsNavControllerAsRoot() {
        let window = UIWindow()
        let auth = InMemoryAuthService()
        let container = AppContainer(auth: auth)
        let sut = AppCoordinator(window: window, container: container)
        sut.start()
        XCTAssertTrue(window.rootViewController is UINavigationController)
    }

    func test_start_whenUnauthenticated_showsSplashInNav() {
        let window = UIWindow()
        let auth = InMemoryAuthService()
        let container = AppContainer(auth: auth)
        let sut = AppCoordinator(window: window, container: container)
        sut.start()
        let nav = window.rootViewController as? UINavigationController
        XCTAssertTrue(nav?.topViewController is SplashViewController)
    }

    func test_whenAuthenticationSucceeds_swapsToTabBarController() {
        let window = UIWindow()
        let auth = InMemoryAuthService()
        let container = AppContainer(auth: auth)
        let sut = AppCoordinator(window: window, container: container)
        sut.start()
        _ = auth.login(email: "test@sushi.ru", password: "secret1")
        XCTAssertTrue(window.rootViewController is UITabBarController)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Use XcodeBuildMCP `test_sim` with `-only-testing:SushiGardenTests/AppCoordinatorTests`.
Expected: FAIL — `test_whenAuthenticationSucceeds_swapsToTabBarController` fails because `setRoot` still sets `MainPlaceholderViewController` (not a `UITabBarController`).

- [ ] **Step 3: Update `Project/Core/Coordinator/AppCoordinator.swift`**

Replace the entire file:

```swift
import UIKit
import Combine

final class AppCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []

    private let window: UIWindow
    private let container: AppContainer
    private var cancellables = Set<AnyCancellable>()

    init(window: UIWindow, container: AppContainer) {
        self.window = window
        self.container = container
    }

    func start() {
        container.auth.isAuthenticatedPublisher
            .removeDuplicates()
            .sink { [weak self] isAuthenticated in
                self?.setRoot(isAuthenticated: isAuthenticated)
            }
            .store(in: &cancellables)
        window.makeKeyAndVisible()
    }

    private func setRoot(isAuthenticated: Bool) {
        if isAuthenticated {
            childCoordinators.removeAll()
            let mainTabCoordinator = MainTabCoordinator(container: container)
            addChild(mainTabCoordinator)
            mainTabCoordinator.start()
            window.rootViewController = mainTabCoordinator.tabBarController
        } else {
            let nav = UINavigationController()
            nav.navigationBar.isHidden = true
            let authCoordinator = AuthCoordinator(navigationController: nav, container: container)
            addChild(authCoordinator)
            authCoordinator.start()
            window.rootViewController = nav
        }
    }
}
```

- [ ] **Step 4: Delete `MainPlaceholderViewController.swift`**

```bash
git rm Project/Placeholders/MainPlaceholderViewController.swift
```

Then run `xcodegen generate` to update `project.pbxproj`.

- [ ] **Step 5: Run all tests**

Use XcodeBuildMCP `test_sim` (full suite — no filter).
Expected: ALL tests PASS. `AppCoordinatorTests` should have 3 tests. Total should be ~75+ unit tests.

If any test fails, diagnose and fix before committing.

- [ ] **Step 6: Commit**

```bash
git add Project/Core/Coordinator/AppCoordinator.swift Tests/Core/AppCoordinatorTests.swift
git commit -m "feat: wire AppCoordinator to MainTabCoordinator; remove MainPlaceholderViewController"
```

---

## Phase 3 done-when

- `xcodegen generate` + `xcodebuild build` succeeds for iOS 17 simulator.
- Full test suite is green (all Phase 1 + 2 tests + all Phase 3 tests).
- Logging in with `test@sushi.ru` / `secret1` shows a `UITabBarController` with 5 tabs.
- Tab 1 shows the Catalog screen: category tabs scroll horizontally, "Роллы" is selected by default, 4 product cards appear in a 2-column grid.
- Tapping a category tab filters products (other categories show empty grid).
- Tapping a product card opens Product Detail: hero image area, name, weight, price, QuantityStepper (starts at 1), "В корзину" button.
- Tapping "+" on a product card in the grid adds it to cart (verifiable by cart badge on tab 3 updating to "1").
- Tapping "В корзину" on Product Detail adds `stepper.count` items to cart and pops back to catalog.

---

## Self-review notes

**Spec coverage:**
- ✅ Tab bar (5 tabs) → `MainTabCoordinator` (Task 9)
- ✅ Catalog screen with category strip → `CatalogViewController` + `CategoryTabCell` (Tasks 2, 5)
- ✅ 2-column product grid → compositional layout in `CatalogViewController` (Task 5)
- ✅ Product cell (image, name, weight, price, + button) → `ProductCell` (Task 3)
- ✅ Product Detail (hero, name, weight, price, stepper, CTA) → Tasks 6–7
- ✅ `QuantityStepper` component → Task 1
- ✅ Add-to-cart from grid card and detail screen → `CatalogViewModel.addToCart`, `ProductDetailViewModel.addToCart`
- ✅ Cart badge updates reactively → `MainTabCoordinator.bindCartBadge` (Task 9)
- ✅ `AppCoordinator` installs tab bar on auth success → Task 10

**Type consistency:**
- `CatalogViewModel.selectProduct(_:)` triggers `onSelectProduct` → `CatalogCoordinator.showDetail(_:)` — ✅
- `ProductDetailViewModel.addToCart(quantity:)` takes `Int` — `ProductDetailViewController` passes `stepper.count: Int` — ✅
- `MainTabCoordinator.tabBarController` is `let` — `AppCoordinator` sets it as `window.rootViewController` — ✅
- `CatalogCoordinator.navigationController` is `let` — `MainTabCoordinator` passes it as tab 0 — ✅

**Placeholder scan:** No TBD/TODO markers. All code blocks are complete.
