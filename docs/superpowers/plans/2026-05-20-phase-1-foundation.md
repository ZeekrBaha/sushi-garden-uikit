# Sushi Garden (UIKit) — Phase 1: Foundation & App Skeleton — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stand up a building, launching pure-UIKit app whose entire domain + mock-service layer is implemented test-first, and whose root navigation is driven by a Coordinator that routes on auth state.

**Architecture:** Pure UIKit + Combine, no storyboards, programmatic Auto Layout. MVVM-C: services behind protocols (in-memory mocks), wired through an `AppContainer` DI object; an `AppCoordinator` owns the window and selects the root view controller from `AuthServicing.isAuthenticated`. This phase ships placeholder roots; Phases 2–5 replace them.

**Tech Stack:** Swift 5.9, iOS 17, UIKit, Combine, XcodeGen, SPM, XCTest. Project at `~/Desktop/llm-ai-projects/sushi-garden-uikit`.

---

## Phase roadmap (this document = Phase 1)

| Phase | Produces | Plan file |
|---|---|---|
| **1. Foundation & App Skeleton** | Building app, tested domain/service layer, coordinator routing to placeholders | *this file* |
| 2. Auth flow | Splash → Register/Login, validation, auth success → main | `…/plans/2026-05-2x-phase-2-auth.md` (written when reached) |
| 3. Catalog + Detail + Cart-add + Tab shell | 5-tab shell, catalog grid, product detail, add to cart, live cart badge | written when reached |
| 4. Cart + Checkout + Orders | Cart screen, MapKit checkout, place order | written when reached |
| 5. Orders / Promotions / Profile | Remaining tab screens | written when reached |

Each later phase gets its own fully-detailed TDD plan before execution.

---

## File structure introduced in Phase 1

```
project.yml                                  XcodeGen project definition
Project/
  App/
    Info.plist                               Scene manifest, no storyboard
    AppDelegate.swift                         @main, scene config
    SceneDelegate.swift                       Builds window, starts AppCoordinator
  Core/
    Coordinator/Coordinator.swift             Coordinator protocol
    Coordinator/AppCoordinator.swift          Root coordinator, auth-driven routing
    DI/AppContainer.swift                     Builds + holds all services
  DesignSystem/
    UIColor+Hex.swift                         Hex initializer
    Colors.swift                              Palette tokens
    Spacing.swift                             Spacing scale
    Typography.swift                          Sen font tokens + system fallback
    FontLoader.swift                          Registers bundled fonts
  Models/
    Category.swift  Product.swift  AddOn.swift  CartItem.swift
    Order.swift  UserProfile.swift  DeliveryAddress.swift
  Services/
    Validation/FieldValidators.swift          Email/password/phone/non-empty
    Catalog/CatalogServicing.swift            Protocol + InMemoryCatalogService
    Cart/CartServicing.swift                  Protocol + InMemoryCartService
    Auth/AuthServicing.swift                  Protocol + AuthError + InMemoryAuthService
    Orders/OrdersServicing.swift              Protocol + InMemoryOrdersService
  Placeholders/
    AuthPlaceholderViewController.swift        Temp root (replaced in Phase 2)
    MainPlaceholderViewController.swift        Temp root (replaced in Phase 3)
Tests/
  DesignSystem/UIColorHexTests.swift
  Models/CartItemTests.swift
  Services/FieldValidatorsTests.swift
  Services/InMemoryCatalogServiceTests.swift
  Services/InMemoryCartServiceTests.swift
  Services/InMemoryAuthServiceTests.swift
  Services/InMemoryOrdersServiceTests.swift
  Core/AppCoordinatorTests.swift
UITests/
  SmokeUITests.swift                          App launches without crashing
```

**Conventions used by every task below**
- Generate the project after editing `project.yml`: `xcodegen generate`
- Run all unit tests: `xcodebuild test -project SushiGarden.xcodeproj -scheme SushiGarden -destination 'platform=iOS Simulator,name=iPhone 16 Pro'`
- Run one test: append `-only-testing:SushiGardenTests/<ClassName>/<test_method>`
- Build only: `xcodebuild build -project SushiGarden.xcodeproj -scheme SushiGarden -destination 'platform=iOS Simulator,name=iPhone 16 Pro'`
- (Equivalent XcodeBuildMCP tools may be used instead of `xcodebuild`.)

---

## Task 1: Project scaffolding (XcodeGen, app entry, build)

**Files:**
- Create: `project.yml`
- Create: `Project/App/Info.plist`
- Create: `Project/App/AppDelegate.swift`
- Create: `Project/App/SceneDelegate.swift`
- Create: `UITests/SmokeUITests.swift`

- [ ] **Step 1: Write `project.yml`**

```yaml
name: SushiGarden
options:
  bundleIdPrefix: com.errornil
  deploymentTarget:
    iOS: "17.0"
  createIntermediateGroups: true
settings:
  base:
    SWIFT_VERSION: "5.9"
    MARKETING_VERSION: "1.0"
    CURRENT_PROJECT_VERSION: "1"
    DEVELOPMENT_LANGUAGE: ru
    TARGETED_DEVICE_FAMILY: "1"
targets:
  SushiGarden:
    type: application
    platform: iOS
    sources:
      - Project
    settings:
      base:
        INFOPLIST_FILE: Project/App/Info.plist
        PRODUCT_BUNDLE_IDENTIFIER: com.errornil.sushigarden
        GENERATE_INFOPLIST_FILE: NO
  SushiGardenTests:
    type: bundle.unit-test
    platform: iOS
    sources:
      - Tests
    dependencies:
      - target: SushiGarden
  SushiGardenUITests:
    type: bundle.ui-testing
    platform: iOS
    sources:
      - UITests
    dependencies:
      - target: SushiGarden
```

- [ ] **Step 2: Write `Project/App/Info.plist`**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>UILaunchScreen</key>
    <dict/>
    <key>UIApplicationSceneManifest</key>
    <dict>
        <key>UIApplicationSupportsMultipleScenes</key>
        <false/>
        <key>UISceneConfigurations</key>
        <dict>
            <key>UIWindowSceneSessionRoleApplication</key>
            <array>
                <dict>
                    <key>UISceneConfigurationName</key>
                    <string>Default Configuration</string>
                    <key>UISceneDelegateClassName</key>
                    <string>$(PRODUCT_MODULE_NAME).SceneDelegate</string>
                </dict>
            </array>
        </dict>
    </dict>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
    </array>
</dict>
</plist>
```

- [ ] **Step 3: Write `Project/App/AppDelegate.swift`**

```swift
import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}
```

- [ ] **Step 4: Write `Project/App/SceneDelegate.swift`** (minimal; coordinator wiring lands in Task 11)

```swift
import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        let placeholder = UIViewController()
        placeholder.view.backgroundColor = .black
        window.rootViewController = placeholder
        window.makeKeyAndVisible()
        self.window = window
    }
}
```

- [ ] **Step 5: Write `UITests/SmokeUITests.swift`**

```swift
import XCTest

final class SmokeUITests: XCTestCase {
    func test_appLaunches() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertEqual(app.state, .runningForeground)
    }
}
```

- [ ] **Step 6: Generate and build**

Run: `xcodegen generate && xcodebuild build -project SushiGarden.xcodeproj -scheme SushiGarden -destination 'platform=iOS Simulator,name=iPhone 16 Pro'`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 7: Commit**

```bash
git add project.yml Project UITests
git commit -m "chore: scaffold UIKit app with XcodeGen, scene manifest, smoke test"
```

---

## Task 2: Color tokens (TDD on hex initializer)

**Files:**
- Create: `Project/DesignSystem/UIColor+Hex.swift`
- Create: `Project/DesignSystem/Colors.swift`
- Test: `Tests/DesignSystem/UIColorHexTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import SushiGarden

final class UIColorHexTests: XCTestCase {
    func test_hexInitializer_parsesAccentRed() {
        let color = UIColor(hex: 0xEC1A35)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        XCTAssertEqual(r, 0xEC / 255, accuracy: 0.001)
        XCTAssertEqual(g, 0x1A / 255, accuracy: 0.001)
        XCTAssertEqual(b, 0x35 / 255, accuracy: 0.001)
        XCTAssertEqual(a, 1.0, accuracy: 0.001)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -project SushiGarden.xcodeproj -scheme SushiGarden -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:SushiGardenTests/UIColorHexTests/test_hexInitializer_parsesAccentRed`
Expected: FAIL — `UIColor(hex:)` does not exist (compile error).

- [ ] **Step 3: Write `Project/DesignSystem/UIColor+Hex.swift`**

```swift
import UIKit

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1.0) {
        let r = CGFloat((hex >> 16) & 0xFF) / 255
        let g = CGFloat((hex >> 8) & 0xFF) / 255
        let b = CGFloat(hex & 0xFF) / 255
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
}
```

- [ ] **Step 4: Write `Project/DesignSystem/Colors.swift`**

```swift
import UIKit

enum AppColor {
    static let background = UIColor(hex: 0x0F0F11)
    static let surface = UIColor(hex: 0x161616)
    static let elevated = UIColor(hex: 0x29282C)
    static let accent = UIColor(hex: 0xEC1A35)
    static let textPrimary = UIColor.white
    static let textSecondary = UIColor(hex: 0x6C6C74)
    static let inactive = UIColor(hex: 0x4C4C4C)
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: same command as Step 2.
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add Project/DesignSystem/UIColor+Hex.swift Project/DesignSystem/Colors.swift Tests/DesignSystem/UIColorHexTests.swift
git commit -m "feat: add color tokens with tested hex initializer"
```

---

## Task 3: Spacing + Typography tokens (no behavior to test; build only)

**Files:**
- Create: `Project/DesignSystem/Spacing.swift`
- Create: `Project/DesignSystem/Typography.swift`
- Create: `Project/DesignSystem/FontLoader.swift`

- [ ] **Step 1: Write `Project/DesignSystem/Spacing.swift`**

```swift
import CoreGraphics

enum Spacing {
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 16
    static let l: CGFloat = 24
    static let xl: CGFloat = 32

    static let cardRadius: CGFloat = 12
    static let bannerRadius: CGFloat = 21
}
```

- [ ] **Step 2: Write `Project/DesignSystem/Typography.swift`**

`AppFont.sen(...)` returns the bundled "Sen" font when available and falls back to the system font of the same size/weight, so the app builds and runs before the font files are added.

```swift
import UIKit

enum AppFont {
    static func sen(_ size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        let name = weight == .bold ? "Sen-Bold" : "Sen-Regular"
        return UIFont(name: name, size: size) ?? .systemFont(ofSize: size, weight: weight)
    }

    // Semantic styles from the Figma.
    static var price: UIFont { sen(19, weight: .bold) }
    static var productTitle: UIFont { sen(16.5, weight: .bold) }
    static var categoryTab: UIFont { sen(15.8, weight: .bold) }
    static var weight: UIFont { sen(14) }
    static var caption: UIFont { sen(12) }
    static var tabLabel: UIFont { sen(11.8) }
}
```

- [ ] **Step 3: Write `Project/DesignSystem/FontLoader.swift`**

Registers any bundled `.ttf` fonts at launch. Safe to call before fonts exist (it simply finds nothing).

```swift
import UIKit
import CoreText

enum FontLoader {
    /// Registers all bundled custom fonts. No-op if none are present yet.
    static func registerCustomFonts() {
        let exts = ["ttf", "otf"]
        for ext in exts {
            let urls = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: nil) ?? []
            for url in urls {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
    }
}
```

- [ ] **Step 4: Build to verify it compiles**

Run: `xcodegen generate && xcodebuild build -project SushiGarden.xcodeproj -scheme SushiGarden -destination 'platform=iOS Simulator,name=iPhone 16 Pro'`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add Project/DesignSystem/Spacing.swift Project/DesignSystem/Typography.swift Project/DesignSystem/FontLoader.swift
git commit -m "feat: add spacing + typography tokens with system-font fallback"
```

---

## Task 4: Domain models (TDD on `CartItem.subtotal`)

**Files:**
- Create: `Project/Models/Category.swift`
- Create: `Project/Models/Product.swift`
- Create: `Project/Models/AddOn.swift`
- Create: `Project/Models/CartItem.swift`
- Create: `Project/Models/Order.swift`
- Create: `Project/Models/UserProfile.swift`
- Create: `Project/Models/DeliveryAddress.swift`
- Test: `Tests/Models/CartItemTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import SushiGarden

final class CartItemTests: XCTestCase {
    private func makeProduct(price: Int) -> Product {
        Product(id: "p1", name: "Айдахо маки", categoryId: "rolls",
                weightGrams: 285, price: price, imageName: "idaho", description: "")
    }

    func test_subtotal_isPriceTimesQuantity() {
        let item = CartItem(product: makeProduct(price: 810), quantity: 3)
        XCTAssertEqual(item.subtotal, 2430)
    }

    func test_subtotal_singleQuantity_equalsPrice() {
        let item = CartItem(product: makeProduct(price: 620), quantity: 1)
        XCTAssertEqual(item.subtotal, 620)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test ... -only-testing:SushiGardenTests/CartItemTests`
Expected: FAIL — `Product` / `CartItem` undefined (compile error).

- [ ] **Step 3: Write the model files**

`Project/Models/Category.swift`
```swift
struct Category: Identifiable, Equatable, Hashable {
    let id: String
    let name: String
}
```

`Project/Models/Product.swift`
```swift
struct Product: Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    let categoryId: String
    let weightGrams: Int
    let price: Int          // whole rubles
    let imageName: String
    let description: String
}
```

`Project/Models/AddOn.swift`
```swift
struct AddOn: Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    let price: Int
}
```

`Project/Models/CartItem.swift`
```swift
struct CartItem: Identifiable, Equatable, Hashable {
    let product: Product
    var quantity: Int

    var id: String { product.id }
    var subtotal: Int { product.price * quantity }
}
```

`Project/Models/Order.swift`
```swift
import Foundation

struct Order: Identifiable, Equatable, Hashable {
    enum Status: String, Equatable { case placed, cooking, delivering, delivered }

    let id: String
    let items: [CartItem]
    let total: Int
    let createdAt: Date
    var status: Status
}
```

`Project/Models/UserProfile.swift`
```swift
struct UserProfile: Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    let phone: String
    let email: String
}
```

`Project/Models/DeliveryAddress.swift`
```swift
struct DeliveryAddress: Equatable, Hashable {
    let city: String
    let street: String
    let building: String

    var formatted: String { "\(city), \(street) \(building)" }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: same as Step 2.
Expected: PASS (both tests).

- [ ] **Step 5: Commit**

```bash
git add Project/Models Tests/Models/CartItemTests.swift
git commit -m "feat: add domain models with tested CartItem.subtotal"
```

---

## Task 5: Field validators (TDD)

**Files:**
- Create: `Project/Services/Validation/FieldValidators.swift`
- Test: `Tests/Services/FieldValidatorsTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import SushiGarden

final class FieldValidatorsTests: XCTestCase {
    func test_email_validAndInvalid() {
        XCTAssertTrue(FieldValidators.isValidEmail("user@example.com"))
        XCTAssertFalse(FieldValidators.isValidEmail("user@"))
        XCTAssertFalse(FieldValidators.isValidEmail("nope"))
        XCTAssertFalse(FieldValidators.isValidEmail(""))
    }

    func test_password_requiresMinimumSixCharacters() {
        XCTAssertTrue(FieldValidators.isValidPassword("secret1"))
        XCTAssertFalse(FieldValidators.isValidPassword("12345"))
    }

    func test_phone_requiresAtLeastTenDigits() {
        XCTAssertTrue(FieldValidators.isValidPhone("+7 999 123 45 67"))
        XCTAssertFalse(FieldValidators.isValidPhone("12345"))
    }

    func test_nonEmpty_trimsWhitespace() {
        XCTAssertTrue(FieldValidators.isNonEmpty("  Баха  "))
        XCTAssertFalse(FieldValidators.isNonEmpty("   "))
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test ... -only-testing:SushiGardenTests/FieldValidatorsTests`
Expected: FAIL — `FieldValidators` undefined.

- [ ] **Step 3: Write `Project/Services/Validation/FieldValidators.swift`**

```swift
import Foundation

enum FieldValidators {
    static func isValidEmail(_ value: String) -> Bool {
        let pattern = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        return value.range(of: pattern, options: .regularExpression) != nil
    }

    static func isValidPassword(_ value: String) -> Bool {
        value.count >= 6
    }

    static func isValidPhone(_ value: String) -> Bool {
        value.filter(\.isNumber).count >= 10
    }

    static func isNonEmpty(_ value: String) -> Bool {
        !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: same as Step 2.
Expected: PASS (all four tests).

- [ ] **Step 5: Commit**

```bash
git add Project/Services/Validation/FieldValidators.swift Tests/Services/FieldValidatorsTests.swift
git commit -m "feat: add field validators (email, password, phone, non-empty)"
```

---

## Task 6: Catalog service (TDD)

**Files:**
- Create: `Project/Services/Catalog/CatalogServicing.swift`
- Test: `Tests/Services/InMemoryCatalogServiceTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import SushiGarden

final class InMemoryCatalogServiceTests: XCTestCase {
    func test_categories_includeFigmaSections() {
        let service = InMemoryCatalogService()
        let names = service.categories().map(\.name)
        XCTAssertTrue(names.contains("Суши"))
        XCTAssertTrue(names.contains("Роллы"))
        XCTAssertTrue(names.contains("WOK"))
    }

    func test_products_inCategory_areFiltered() {
        let service = InMemoryCatalogService()
        guard let rolls = service.categories().first(where: { $0.name == "Роллы" }) else {
            return XCTFail("Роллы category missing")
        }
        let products = service.products(in: rolls.id)
        XCTAssertFalse(products.isEmpty)
        XCTAssertTrue(products.allSatisfy { $0.categoryId == rolls.id })
    }

    func test_products_inUnknownCategory_isEmpty() {
        let service = InMemoryCatalogService()
        XCTAssertTrue(service.products(in: "does-not-exist").isEmpty)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test ... -only-testing:SushiGardenTests/InMemoryCatalogServiceTests`
Expected: FAIL — `CatalogServicing` / `InMemoryCatalogService` undefined.

- [ ] **Step 3: Write `Project/Services/Catalog/CatalogServicing.swift`**

```swift
import Foundation

protocol CatalogServicing {
    func categories() -> [Category]
    func products(in categoryId: String) -> [Product]
    func allProducts() -> [Product]
}

final class InMemoryCatalogService: CatalogServicing {
    private let _categories: [Category] = [
        Category(id: "sushi", name: "Суши"),
        Category(id: "rolls", name: "Роллы"),
        Category(id: "hot_rolls", name: "Горячие роллы"),
        Category(id: "salads", name: "Салаты"),
        Category(id: "wok", name: "WOK"),
    ]

    private let _products: [Product] = [
        Product(id: "hikari", name: "Хикари", categoryId: "rolls",
                weightGrams: 255, price: 620, imageName: "hikari", description: ""),
        Product(id: "los_angeles", name: "Лос-Анджелес", categoryId: "rolls",
                weightGrams: 285, price: 707, imageName: "los_angeles", description: ""),
        Product(id: "idaho", name: "Айдахо маки", categoryId: "rolls",
                weightGrams: 285, price: 810, imageName: "idaho", description: ""),
        Product(id: "osaka", name: "Осака маки", categoryId: "rolls",
                weightGrams: 275, price: 740, imageName: "osaka", description: ""),
    ]

    func categories() -> [Category] { _categories }

    func products(in categoryId: String) -> [Product] {
        _products.filter { $0.categoryId == categoryId }
    }

    func allProducts() -> [Product] { _products }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: same as Step 2.
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Project/Services/Catalog/CatalogServicing.swift Tests/Services/InMemoryCatalogServiceTests.swift
git commit -m "feat: add in-memory catalog service with Figma menu data"
```

---

## Task 7: Cart service (TDD, Combine publisher)

**Files:**
- Create: `Project/Services/Cart/CartServicing.swift`
- Test: `Tests/Services/InMemoryCartServiceTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
import Combine
@testable import SushiGarden

final class InMemoryCartServiceTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()

    private func product(_ id: String, _ price: Int) -> Product {
        Product(id: id, name: id, categoryId: "rolls", weightGrams: 100,
                price: price, imageName: id, description: "")
    }

    func test_add_incrementsQuantityForSameProduct() {
        let cart = InMemoryCartService()
        cart.add(product("idaho", 810))
        cart.add(product("idaho", 810))
        XCTAssertEqual(cart.items.count, 1)
        XCTAssertEqual(cart.items.first?.quantity, 2)
        XCTAssertEqual(cart.totalCount, 2)
        XCTAssertEqual(cart.totalPrice, 1620)
    }

    func test_setQuantity_toZero_removesItem() {
        let cart = InMemoryCartService()
        cart.add(product("osaka", 740))
        cart.setQuantity(0, for: "osaka")
        XCTAssertTrue(cart.items.isEmpty)
    }

    func test_itemsPublisher_emitsOnChange() {
        let cart = InMemoryCartService()
        var received: [[CartItem]] = []
        cart.itemsPublisher
            .sink { received.append($0) }
            .store(in: &cancellables)

        cart.add(product("hikari", 620))

        // One emission for the initial value, one after add.
        XCTAssertEqual(received.count, 2)
        XCTAssertEqual(received.last?.first?.product.id, "hikari")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test ... -only-testing:SushiGardenTests/InMemoryCartServiceTests`
Expected: FAIL — `CartServicing` / `InMemoryCartService` undefined.

- [ ] **Step 3: Write `Project/Services/Cart/CartServicing.swift`**

```swift
import Foundation
import Combine

protocol CartServicing {
    var items: [CartItem] { get }
    var itemsPublisher: AnyPublisher<[CartItem], Never> { get }
    var totalCount: Int { get }
    var totalPrice: Int { get }
    func add(_ product: Product)
    func setQuantity(_ quantity: Int, for productId: String)
    func remove(productId: String)
    func clear()
}

final class InMemoryCartService: CartServicing {
    private let subject = CurrentValueSubject<[CartItem], Never>([])

    var items: [CartItem] { subject.value }
    var itemsPublisher: AnyPublisher<[CartItem], Never> { subject.eraseToAnyPublisher() }
    var totalCount: Int { items.reduce(0) { $0 + $1.quantity } }
    var totalPrice: Int { items.reduce(0) { $0 + $1.subtotal } }

    func add(_ product: Product) {
        var current = subject.value
        if let index = current.firstIndex(where: { $0.product.id == product.id }) {
            current[index].quantity += 1
        } else {
            current.append(CartItem(product: product, quantity: 1))
        }
        subject.send(current)
    }

    func setQuantity(_ quantity: Int, for productId: String) {
        var current = subject.value
        guard let index = current.firstIndex(where: { $0.product.id == productId }) else { return }
        if quantity <= 0 {
            current.remove(at: index)
        } else {
            current[index].quantity = quantity
        }
        subject.send(current)
    }

    func remove(productId: String) {
        subject.send(subject.value.filter { $0.product.id != productId })
    }

    func clear() {
        subject.send([])
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: same as Step 2.
Expected: PASS (all three tests).

- [ ] **Step 5: Commit**

```bash
git add Project/Services/Cart/CartServicing.swift Tests/Services/InMemoryCartServiceTests.swift
git commit -m "feat: add in-memory cart service with Combine items publisher"
```

---

## Task 8: Auth service (TDD, Combine auth-state)

**Files:**
- Create: `Project/Services/Auth/AuthServicing.swift`
- Test: `Tests/Services/InMemoryAuthServiceTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
import Combine
@testable import SushiGarden

final class InMemoryAuthServiceTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()

    func test_login_withSeededCredentials_succeedsAndPublishesAuthenticated() {
        let auth = InMemoryAuthService()
        var states: [Bool] = []
        auth.isAuthenticatedPublisher.sink { states.append($0) }.store(in: &cancellables)

        let result = auth.login(email: "test@sushi.ru", password: "secret1")

        switch result {
        case .success(let user): XCTAssertEqual(user.email, "test@sushi.ru")
        case .failure: XCTFail("expected success")
        }
        XCTAssertTrue(auth.isAuthenticated)
        XCTAssertEqual(states, [false, true])
    }

    func test_login_withWrongPassword_fails() {
        let auth = InMemoryAuthService()
        let result = auth.login(email: "test@sushi.ru", password: "wrong")
        if case .success = result { XCTFail("expected failure") }
        XCTAssertFalse(auth.isAuthenticated)
    }

    func test_register_createsUserAndAuthenticates() {
        let auth = InMemoryAuthService()
        let result = auth.register(name: "Баха", phone: "+79991234567",
                                   email: "new@sushi.ru", password: "secret1")
        if case .failure = result { XCTFail("expected success") }
        XCTAssertTrue(auth.isAuthenticated)
    }

    func test_logout_publishesUnauthenticated() {
        let auth = InMemoryAuthService()
        _ = auth.login(email: "test@sushi.ru", password: "secret1")
        auth.logout()
        XCTAssertFalse(auth.isAuthenticated)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test ... -only-testing:SushiGardenTests/InMemoryAuthServiceTests`
Expected: FAIL — `AuthServicing` / `InMemoryAuthService` undefined.

- [ ] **Step 3: Write `Project/Services/Auth/AuthServicing.swift`**

```swift
import Foundation
import Combine

enum AuthError: Error, Equatable {
    case invalidCredentials
    case emailTaken
}

protocol AuthServicing {
    var isAuthenticated: Bool { get }
    var isAuthenticatedPublisher: AnyPublisher<Bool, Never> { get }
    var currentUser: UserProfile? { get }
    func login(email: String, password: String) -> Result<UserProfile, AuthError>
    func register(name: String, phone: String, email: String, password: String) -> Result<UserProfile, AuthError>
    func logout()
}

final class InMemoryAuthService: AuthServicing {
    private struct Account { let user: UserProfile; let password: String }

    private var accounts: [String: Account]
    private let authSubject = CurrentValueSubject<Bool, Never>(false)
    private(set) var currentUser: UserProfile?

    init() {
        let seeded = UserProfile(id: "seed", name: "Тест",
                                 phone: "+79990000000", email: "test@sushi.ru")
        accounts = ["test@sushi.ru": Account(user: seeded, password: "secret1")]
    }

    var isAuthenticated: Bool { authSubject.value }
    var isAuthenticatedPublisher: AnyPublisher<Bool, Never> { authSubject.eraseToAnyPublisher() }

    func login(email: String, password: String) -> Result<UserProfile, AuthError> {
        guard let account = accounts[email], account.password == password else {
            return .failure(.invalidCredentials)
        }
        currentUser = account.user
        authSubject.send(true)
        return .success(account.user)
    }

    func register(name: String, phone: String, email: String, password: String) -> Result<UserProfile, AuthError> {
        guard accounts[email] == nil else { return .failure(.emailTaken) }
        let user = UserProfile(id: UUID().uuidString, name: name, phone: phone, email: email)
        accounts[email] = Account(user: user, password: password)
        currentUser = user
        authSubject.send(true)
        return .success(user)
    }

    func logout() {
        currentUser = nil
        authSubject.send(false)
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: same as Step 2.
Expected: PASS (all four tests).

- [ ] **Step 5: Commit**

```bash
git add Project/Services/Auth/AuthServicing.swift Tests/Services/InMemoryAuthServiceTests.swift
git commit -m "feat: add in-memory auth service with Combine auth-state"
```

---

## Task 9: Orders service (TDD)

**Files:**
- Create: `Project/Services/Orders/OrdersServicing.swift`
- Test: `Tests/Services/InMemoryOrdersServiceTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import SushiGarden

final class InMemoryOrdersServiceTests: XCTestCase {
    func test_placeOrder_appendsOrderWithComputedTotal() {
        let service = InMemoryOrdersService()
        let product = Product(id: "idaho", name: "Айдахо маки", categoryId: "rolls",
                              weightGrams: 285, price: 810, imageName: "idaho", description: "")
        let items = [CartItem(product: product, quantity: 2)]
        let address = DeliveryAddress(city: "Воронеж", street: "Мира", building: "36")

        let order = service.placeOrder(items: items, address: address)

        XCTAssertEqual(order.total, 1620)
        XCTAssertEqual(order.status, .placed)
        XCTAssertEqual(service.orders.count, 1)
        XCTAssertEqual(service.orders.first?.id, order.id)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test ... -only-testing:SushiGardenTests/InMemoryOrdersServiceTests`
Expected: FAIL — `OrdersServicing` / `InMemoryOrdersService` undefined.

- [ ] **Step 3: Write `Project/Services/Orders/OrdersServicing.swift`**

```swift
import Foundation
import Combine

protocol OrdersServicing {
    var orders: [Order] { get }
    var ordersPublisher: AnyPublisher<[Order], Never> { get }
    @discardableResult
    func placeOrder(items: [CartItem], address: DeliveryAddress) -> Order
}

final class InMemoryOrdersService: OrdersServicing {
    private let subject = CurrentValueSubject<[Order], Never>([])

    var orders: [Order] { subject.value }
    var ordersPublisher: AnyPublisher<[Order], Never> { subject.eraseToAnyPublisher() }

    @discardableResult
    func placeOrder(items: [CartItem], address: DeliveryAddress) -> Order {
        let total = items.reduce(0) { $0 + $1.subtotal }
        let order = Order(id: UUID().uuidString, items: items, total: total,
                          createdAt: Date(), status: .placed)
        subject.send(subject.value + [order])
        return order
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: same as Step 2.
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Project/Services/Orders/OrdersServicing.swift Tests/Services/InMemoryOrdersServiceTests.swift
git commit -m "feat: add in-memory orders service with computed totals"
```

---

## Task 10: Coordinator protocol + DI container (build only)

**Files:**
- Create: `Project/Core/Coordinator/Coordinator.swift`
- Create: `Project/Core/DI/AppContainer.swift`

- [ ] **Step 1: Write `Project/Core/Coordinator/Coordinator.swift`**

```swift
import UIKit

protocol Coordinator: AnyObject {
    var childCoordinators: [Coordinator] { get set }
    func start()
}

extension Coordinator {
    func addChild(_ child: Coordinator) {
        childCoordinators.append(child)
    }

    func removeChild(_ child: Coordinator) {
        childCoordinators.removeAll { $0 === child }
    }
}
```

- [ ] **Step 2: Write `Project/Core/DI/AppContainer.swift`**

```swift
import Foundation

/// Builds and holds the app's services. Single source of dependencies,
/// injected into coordinators and view models.
final class AppContainer {
    let auth: AuthServicing
    let catalog: CatalogServicing
    let cart: CartServicing
    let orders: OrdersServicing

    init(
        auth: AuthServicing = InMemoryAuthService(),
        catalog: CatalogServicing = InMemoryCatalogService(),
        cart: CartServicing = InMemoryCartService(),
        orders: OrdersServicing = InMemoryOrdersService()
    ) {
        self.auth = auth
        self.catalog = catalog
        self.cart = cart
        self.orders = orders
    }
}
```

- [ ] **Step 3: Build to verify it compiles**

Run: `xcodegen generate && xcodebuild build -project SushiGarden.xcodeproj -scheme SushiGarden -destination 'platform=iOS Simulator,name=iPhone 16 Pro'`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add Project/Core/Coordinator/Coordinator.swift Project/Core/DI/AppContainer.swift
git commit -m "feat: add Coordinator protocol and AppContainer DI"
```

---

## Task 11: AppCoordinator routing + placeholders + scene wiring (TDD on routing)

**Files:**
- Create: `Project/Placeholders/AuthPlaceholderViewController.swift`
- Create: `Project/Placeholders/MainPlaceholderViewController.swift`
- Create: `Project/Core/Coordinator/AppCoordinator.swift`
- Modify: `Project/App/SceneDelegate.swift`
- Test: `Tests/Core/AppCoordinatorTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import SushiGarden

final class AppCoordinatorTests: XCTestCase {
    func test_start_whenUnauthenticated_setsAuthPlaceholderRoot() {
        let window = UIWindow()
        let container = AppContainer()      // seeded auth = logged out
        let sut = AppCoordinator(window: window, container: container)

        sut.start()

        XCTAssertTrue(window.rootViewController is AuthPlaceholderViewController)
    }

    func test_whenAuthenticationSucceeds_swapsToMainPlaceholderRoot() {
        let window = UIWindow()
        let auth = InMemoryAuthService()
        let container = AppContainer(auth: auth)
        let sut = AppCoordinator(window: window, container: container)
        sut.start()

        _ = auth.login(email: "test@sushi.ru", password: "secret1")

        XCTAssertTrue(window.rootViewController is MainPlaceholderViewController)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test ... -only-testing:SushiGardenTests/AppCoordinatorTests`
Expected: FAIL — `AppCoordinator` / placeholders undefined.

- [ ] **Step 3: Write the placeholders**

`Project/Placeholders/AuthPlaceholderViewController.swift`
```swift
import UIKit

/// Temporary auth root. Replaced by AuthCoordinator in Phase 2.
final class AuthPlaceholderViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColor.background
        let label = UILabel()
        label.text = "Auth (Phase 2)"
        label.textColor = AppColor.textPrimary
        label.font = AppFont.productTitle
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
}
```

`Project/Placeholders/MainPlaceholderViewController.swift`
```swift
import UIKit

/// Temporary main root. Replaced by MainTabCoordinator in Phase 3.
final class MainPlaceholderViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColor.background
        let label = UILabel()
        label.text = "Main (Phase 3)"
        label.textColor = AppColor.textPrimary
        label.font = AppFont.productTitle
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
}
```

- [ ] **Step 4: Write `Project/Core/Coordinator/AppCoordinator.swift`**

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
            .receive(on: RunLoop.main)
            .sink { [weak self] isAuthenticated in
                self?.setRoot(isAuthenticated: isAuthenticated)
            }
            .store(in: &cancellables)
        window.makeKeyAndVisible()
    }

    private func setRoot(isAuthenticated: Bool) {
        // Phase 2/3 swap these placeholders for AuthCoordinator / MainTabCoordinator.
        window.rootViewController = isAuthenticated
            ? MainPlaceholderViewController()
            : AuthPlaceholderViewController()
    }
}
```

Note: in tests there is no run loop pumping, so the initial `sink` and the post-login `sink` both deliver synchronously enough for `removeDuplicates()` + `CurrentValueSubject`. If the `receive(on: RunLoop.main)` makes the test asynchronous, replace it with `.receive(on: DispatchQueue.main)` and add an `expectation`; simplest for testability is to drop the scheduler hop here since `setRoot` is already main-thread in app use. **Implementation choice: remove the `.receive(on:)` line** so routing is synchronous and unit-testable:

```swift
container.auth.isAuthenticatedPublisher
    .removeDuplicates()
    .sink { [weak self] isAuthenticated in
        self?.setRoot(isAuthenticated: isAuthenticated)
    }
    .store(in: &cancellables)
```

- [ ] **Step 5: Run test to verify it passes**

Run: same as Step 2.
Expected: PASS (both tests).

- [ ] **Step 6: Wire `SceneDelegate` to the coordinator**

Replace `Project/App/SceneDelegate.swift` with:

```swift
import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var appCoordinator: AppCoordinator?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }
        FontLoader.registerCustomFonts()
        let window = UIWindow(windowScene: windowScene)
        let coordinator = AppCoordinator(window: window, container: AppContainer())
        self.window = window
        self.appCoordinator = coordinator
        coordinator.start()
    }
}
```

- [ ] **Step 7: Run the full suite + smoke UI test**

Run: `xcodegen generate && xcodebuild test -project SushiGarden.xcodeproj -scheme SushiGarden -destination 'platform=iOS Simulator,name=iPhone 16 Pro'`
Expected: all unit tests PASS; `SmokeUITests.test_appLaunches` PASS; app shows "Auth (Phase 2)".

- [ ] **Step 8: Commit**

```bash
git add Project/Placeholders Project/Core/Coordinator/AppCoordinator.swift Project/App/SceneDelegate.swift Tests/Core/AppCoordinatorTests.swift
git commit -m "feat: route window root from auth state via AppCoordinator"
```

---

## Phase 1 done-when

- `xcodegen generate` produces a project that builds for iOS 17 simulator.
- Full `xcodebuild test` run is green: `UIColorHexTests`, `CartItemTests`, `FieldValidatorsTests`, `InMemoryCatalogServiceTests`, `InMemoryCartServiceTests`, `InMemoryAuthServiceTests`, `InMemoryOrdersServiceTests`, `AppCoordinatorTests`, `SmokeUITests`.
- Launching the app shows the "Auth (Phase 2)" placeholder; after a (future) login it would swap to "Main (Phase 3)".
- Every domain model and service used by later phases exists and is tested.

## Self-review notes (against the spec)

- **Spec coverage (Phase 1 portion):** project tooling (§3) → Task 1; design tokens (§6) → Tasks 2–3; models (§5/§8) → Task 4; validators + Auth/Catalog/Cart/Orders services (§8) → Tasks 5–9; DI + Coordinator core (§4.1/§4.3) → Tasks 10–11. Auth UI, tab shell, catalog, detail, cart, checkout, orders, promotions, profile (§4.1/§7) are intentionally deferred to Phases 2–5.
- **Placeholder scan:** the "Placeholders/" controllers are real, intentional, shipped code (named so), not plan placeholders; every code step contains complete code.
- **Type consistency:** `Product`, `CartItem.subtotal`, `CartServicing`, `AuthServicing`, `AppContainer`, `Coordinator`, `AppCoordinator(window:container:)` signatures are used identically across Tasks 4–11.
