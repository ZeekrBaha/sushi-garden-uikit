# Sushi Garden (UIKit) — Phase 4: Cart + Checkout Design Spec

**Date:** 2026-05-21
**Status:** Approved
**Phase roadmap context:**

| Phase | Status |
|---|---|
| 1. Foundation & App Skeleton | ✅ Complete |
| 2. Auth flow | ✅ Complete |
| 3. Catalog + Detail + Tab shell | ✅ Complete |
| **4. Cart + Checkout** | **← this spec** |
| 5. Orders / Promotions / Profile | next |

---

## 1. Goal

Build the Cart screen (tab 3) and the Checkout screen. The user can review and edit their cart, enter a delivery address via an interactive MapKit map with a draggable pin + reverse geocoding, and place an order. On order placement the cart is cleared and the app switches instantly to the Orders tab (tab 1).

---

## 2. Decisions

| Area | Decision |
|---|---|
| Cart editing | Stepper min=1; swipe-to-delete row action for removal |
| Map | Full interactive `MKMapView`, draggable annotation pin, centered on Moscow |
| Address | `CLGeocoder.reverseGeocodeLocation` on drag-end (not during drag) |
| Post-order | Instant: `cart.clear()` → `orders.placeOrder(...)` → switch to tab 1. No confirmation screen. |
| Checkout cart snapshot | Cart items and total are snapshotted at checkout entry — `CheckoutViewModel` holds a plain array, not a live publisher |
| Coordinator coupling | `CartCoordinator` receives `onSwitchToOrders: () -> Void` from `MainTabCoordinator` at init — no direct coordinator-to-coordinator reference |

---

## 3. File structure

**New files:**

```
Project/
  DesignSystem/
    CartItemCell.swift
  Features/Main/Cart/
    CartCoordinator.swift
    CartViewModel.swift
    CartViewController.swift
    Checkout/
      CheckoutViewModel.swift
      CheckoutViewController.swift

Tests/Features/Main/Cart/
    CartViewModelTests.swift
    CartViewControllerTests.swift
    CartCoordinatorTests.swift
    Checkout/
      CheckoutViewModelTests.swift
      CheckoutViewControllerTests.swift
```

**Modified:**
- `Project/Features/Main/MainTabCoordinator.swift` — replace cart `UIViewController` placeholder with `CartCoordinator` nav
- `Tests/Features/Main/MainTabCoordinatorTests.swift` — update tab-3 assertion to `UINavigationController`

---

## 4. Component design

### 4.1 CartItemCell (`UITableViewCell`)

- **Layout:** product image (60×60, rounded), name label, price × quantity label, `QuantityStepper` on the right
- **Stepper:** `QuantityStepper` wired to `onQuantityChanged: ((Int) -> Void)?`; min count = 1 (stepper already enforces this)
- **Swipe-to-delete:** leading/trailing swipe action provided by the table view delegate; calls `onRemove: (() -> Void)?`
- `nameLabel`, `priceLabel` are `internal` for test access

### 4.2 CartViewModel

```swift
final class CartViewModel {
    @Published private(set) var items: [CartItem]   // mirrors CartServicing
    var totalPrice: Int { items.reduce(0) { $0 + $1.subtotal } }
    var isEmpty: Bool { items.isEmpty }

    var onCheckout: (() -> Void)?

    func setQuantity(_ quantity: Int, for productId: String)
    func remove(productId: String)
    func checkout()   // fires onCheckout
}
```

Sinks to `CartServicing.itemsPublisher` to keep `items` in sync.

### 4.3 CartViewController

- `UITableView` with `CartItemCell` rows (one section)
- Footer view: total price label + "Оформить заказ" `PrimaryButton`
- Empty state: centered `UILabel` ("Корзина пуста") + hidden footer when `viewModel.isEmpty`
- Binds `viewModel.$items` → `tableView.reloadData()`

### 4.4 CheckoutViewModel

```swift
final class CheckoutViewModel {
    // Snapshot of cart at checkout entry
    let items: [CartItem]
    let totalPrice: Int

    @Published private(set) var address: String = ""        // formatted display string
    @Published private(set) var geocodingFailed: Bool = false
    private(set) var lastDeliveryAddress: DeliveryAddress?  // structured; set alongside address
    var canPlaceOrder: Bool { lastDeliveryAddress != nil }

    var onOrderPlaced: (() -> Void)?

    func reverseGeocode(location: CLLocation)   // calls CLGeocoder; on success maps CLPlacemark → DeliveryAddress (locality→city, thoroughfare→street, subThoroughfare→building); updates address / geocodingFailed
    func placeOrder()                           // guard canPlaceOrder; orders.placeOrder(items: snapshotItems, address: lastDeliveryAddress); cart.clear(); onOrderPlaced?()
}
```

`CLGeocoder` injected via init (default `CLGeocoder()`); `OrdersServicing` and `CartServicing` injected via init.

### 4.5 CheckoutViewController

- Full-screen `MKMapView` (top ~55% of screen)
- Draggable `MKPointAnnotation` pin centered on Moscow (`55.7558° N, 37.6173° E`) on first load
- Address label below the map, updated reactively from `viewModel.$address`
- "Не удалось определить адрес" inline error label, shown when `viewModel.$geocodingFailed` is true
- Order summary: item count + total price
- "Подтвердить заказ" `PrimaryButton` — enabled when `viewModel.canPlaceOrder`
- Tapping confirm → `viewModel.placeOrder()`

Map delegate: `mapView(_:annotationView:didChange:fromOldState:)` fires `viewModel.reverseGeocode(location:)` only when `newState == .none` (drag ended).

### 4.6 CartCoordinator

```swift
final class CartCoordinator: Coordinator {
    init(navigationController: UINavigationController,
         container: AppContainer,
         onSwitchToOrders: @escaping () -> Void)

    func start()          // pushes CartViewController
    // private:
    func showCheckout()   // pushes CheckoutViewController; wires onOrderPlaced
    func orderPlaced()    // navigationController.popToRootViewController; onSwitchToOrders()
}
```

### 4.7 MainTabCoordinator changes

Replace:
```swift
let cartVC = makePlaceholder(title: "Корзина", systemImage: "bag", tag: 3)
```
With:
```swift
let cartNav = UINavigationController()
cartNav.navigationBar.isHidden = true
let cartCoordinator = CartCoordinator(
    navigationController: cartNav,
    container: container,
    onSwitchToOrders: { [weak tabBarController] in
        tabBarController?.selectedIndex = 1
    }
)
addChild(cartCoordinator)
cartCoordinator.start()
cartNav.tabBarItem = UITabBarItem(title: "Корзина", image: UIImage(systemName: "bag"), tag: 3)
```

---

## 5. Data flow

```
User taps "+" on ProductCell / ProductDetailViewController
    → CartServicing.add(product)
    → CartServicing.itemsPublisher fires
    → CartViewModel.$items updates → CartViewController reloads table
    → MainTabCoordinator badge updates

User opens Cart tab
    → CartViewController shows live items

User swipes row → delete
    → CartViewModel.remove(productId:)
    → CartServicing.remove(productId:)

User changes stepper in CartItemCell
    → CartViewModel.setQuantity(_:for:)
    → CartServicing.setQuantity(_:for:)

User taps "Оформить заказ"
    → CartViewModel.checkout() → onCheckout closure
    → CartCoordinator.showCheckout()
    → CheckoutViewController pushed with snapshot of current cart

User drags pin on map (drag ends)
    → CheckoutViewModel.reverseGeocode(location:)
    → CLGeocoder.reverseGeocodeLocation → address updated

User taps "Подтвердить заказ"
    → CheckoutViewModel.placeOrder()
    → OrdersServicing.placeOrder(items:address:)
    → CartServicing.clear()
    → onOrderPlaced closure
    → CartCoordinator.orderPlaced()
    → popToRootViewController + onSwitchToOrders()
    → tabBarController.selectedIndex = 1
```

---

## 6. Error handling and edge cases

| Scenario | Behaviour |
|---|---|
| Geocoding returns error | `geocodingFailed = true`; inline error label shown; address unchanged; CTA stays disabled if no prior address |
| Geocoding returns empty placemarks | Same as error |
| Cart empty when Cart tab opened | Empty state label shown; Checkout CTA hidden |
| Cart emptied while on Checkout screen | Not possible — Checkout holds a snapshot; no live cart reference |
| Stepper at minimum (1) tapped down | Blocked by `QuantityStepper` (already enforces min=1) |
| Multiple rapid geocode requests | Only one `CLGeocoder` request active at a time — cancel previous before starting new |

---

## 7. Testing strategy

### CartViewModelTests
- `items` reflects `CartServicing` initial state
- `items` updates when service changes (via publisher)
- `totalPrice` math correct
- `isEmpty` true when no items
- `setQuantity` forwarded to service
- `remove` forwarded to service
- `checkout()` fires `onCheckout`

### CheckoutViewModelTests (mock CLGeocoder)
- `address` updates on successful reverse geocode
- `geocodingFailed` set on geocoder error
- `canPlaceOrder` false when address empty, true when non-empty
- `placeOrder()` calls `orders.placeOrder(items:address:)` with correct items
- `placeOrder()` calls `cart.clear()`
- `placeOrder()` fires `onOrderPlaced`
- `placeOrder()` no-ops when `canPlaceOrder` is false

### CartCoordinatorTests
- `start()` sets `CartViewController` as root
- `onCheckout` closure pushes `CheckoutViewController`
- `onOrderPlaced` calls `onSwitchToOrders`

### CartViewControllerTests / CheckoutViewControllerTests
- Load without crashing
- `viewModel` is exposed

### MainTabCoordinatorTests update
- Tab 3 is `UINavigationController` (was `UIViewController`)
- Tab 3 root is `CartViewController`
