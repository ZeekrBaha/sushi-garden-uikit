# Phase 5: Orders / Promotions / Profile — Design Spec

## Overview

Phase 5 completes the main tab bar by replacing three placeholder view controllers with real screens:
- **Tab 1 (Заказы)** — Order history list
- **Tab 2 (Акции)** — Static promotional banners
- **Tab 4 (Профиль)** — User profile display + logout

All three follow the same MVVM-C pattern established in earlier phases.

---

## Architecture

### New Files

| Path | Purpose |
|------|---------|
| `Project/Models/Promotion.swift` | Plain `Promotion` struct |
| `Project/Features/Main/Orders/OrdersCoordinator.swift` | Wires Orders VM + VC |
| `Project/Features/Main/Orders/OrdersViewModel.swift` | Reactive wrapper over `OrdersServicing` |
| `Project/Features/Main/Orders/OrdersViewController.swift` | UITableView + OrderSummaryCell |
| `Project/Features/Main/Promotions/PromotionsCoordinator.swift` | Wires Promotions VC |
| `Project/Features/Main/Promotions/PromotionsViewController.swift` | Static table of promotion cards |
| `Project/Features/Main/Profile/ProfileCoordinator.swift` | Wires Profile VM + VC, owns onLogout callback |
| `Project/Features/Main/Profile/ProfileViewModel.swift` | Reads currentUser, calls auth.logout() |
| `Project/Features/Main/Profile/ProfileViewController.swift` | Avatar + info rows + logout button |

### Modified Files

| Path | Change |
|------|--------|
| `Project/Features/Main/MainTabCoordinator.swift` | Replace 3 `makePlaceholder` calls with child coordinators |
| `project.yml` | Add new file paths to target sources (XcodeGen) |

### Coordinator Wiring in MainTabCoordinator

`MainTabCoordinator` creates three new child coordinators in `start()`:

```swift
let ordersNav = UINavigationController()
let ordersCoordinator = OrdersCoordinator(navigationController: ordersNav, container: container)
addChild(ordersCoordinator)
ordersCoordinator.start()
ordersNav.tabBarItem = UITabBarItem(title: "Заказы", image: UIImage(systemName: "list.bullet"), tag: 1)

let promotionsNav = UINavigationController()
let promotionsCoordinator = PromotionsCoordinator(navigationController: promotionsNav)
addChild(promotionsCoordinator)
promotionsCoordinator.start()
promotionsNav.tabBarItem = UITabBarItem(title: "Акции", image: UIImage(systemName: "tag"), tag: 2)

let profileNav = UINavigationController()
let profileCoordinator = ProfileCoordinator(
    navigationController: profileNav,
    container: container,
    onLogout: { [weak self] in self?.handleLogout() })
addChild(profileCoordinator)
profileCoordinator.start()
profileNav.tabBarItem = UITabBarItem(title: "Профиль", image: UIImage(systemName: "person"), tag: 4)
```

`handleLogout()` is a private method that calls `container.auth.logout()` — `AppCoordinator` already listens to `isAuthenticatedPublisher` and switches to the auth flow when it emits `false`.

The `tabBarController.viewControllers` array becomes:
`[catalogNav, ordersNav, promotionsNav, cartNav, profileNav]`

---

## Orders Screen

### OrdersViewModel

```swift
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

Same pattern as `CartViewModel`: sync init from `.orders`, then `.dropFirst().receive(on: .main)` for mutations.

### OrdersViewController

- `UITableView` filling the view
- Each row: `OrderSummaryCell` (custom `UITableViewCell`)
- Empty state: centred `UILabel` "No orders yet" shown when `viewModel.isEmpty`
- Navigation bar title: "Заказы"
- Binds `viewModel.$orders` with `.receive(on: DispatchQueue.main).sink` to reload the table

### OrderSummaryCell Layout

```
┌────────────────────────────────────────┐
│  📅 21 May        3 items     ¥1,200   │
│                          [Cooking]     │
└────────────────────────────────────────┘
```

- Left: date formatted as "d MMM" + item count as "N items"
- Right: total price + status badge label with coloured background:
  - `.placed` → gray
  - `.cooking` → orange
  - `.delivering` → blue
  - `.delivered` → green

### OrdersCoordinator

```swift
final class OrdersCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    let navigationController: UINavigationController
    private let container: AppContainer

    init(navigationController: UINavigationController, container: AppContainer)

    func start() {
        let vm = OrdersViewModel(service: container.orders)
        let vc = OrdersViewController(viewModel: vm)
        navigationController.setViewControllers([vc], animated: false)
    }
}
```

---

## Promotions Screen

### Promotion Model

```swift
struct Promotion: Identifiable {
    let id: String
    let title: String
    let description: String
    let imageName: String   // SF Symbol name used as placeholder image
}
```

File: `Project/Models/Promotion.swift`

### Seed Data (hardcoded in PromotionsViewController)

```swift
private let promotions: [Promotion] = [
    Promotion(id: "1", title: "Бесплатная доставка", description: "При заказе от 1500 ₽", imageName: "bicycle"),
    Promotion(id: "2", title: "Ролл в подарок", description: "При первом заказе — бесплатный ролл", imageName: "gift"),
    Promotion(id: "3", title: "Скидка 10%", description: "По вторникам на все сеты", imageName: "percent"),
    Promotion(id: "4", title: "Комбо-обед", description: "Суп + ролл + напиток за 799 ₽", imageName: "fork.knife"),
]
```

### PromotionsViewController

- `UITableView` with static `promotions` array
- `PromotionBannerCell`: SF Symbol icon (48×48) on the left, `titleLabel` bold + `descriptionLabel` secondary on the right
- Navigation bar title: "Акции"
- No ViewModel (static data, no reactive logic)
- Not unit-tested

### PromotionsCoordinator

```swift
final class PromotionsCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    let navigationController: UINavigationController

    init(navigationController: UINavigationController)

    func start() {
        let vc = PromotionsViewController()
        navigationController.setViewControllers([vc], animated: false)
    }
}
```

---

## Profile Screen

### ProfileViewModel

```swift
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

No `@Published` properties — profile is read once on init and the screen is not reactive.

### ProfileViewController Layout

```
┌──────────────────────────────────────┐
│                                      │
│           [ AB ]  ← initials circle  │
│           Alex Baha                  │
│                                      │
│  👤  Alex Baha                       │
│  📞  +7 999 123 45 67                │
│  ✉️  alex@example.com               │
│                                      │
│  [ Выйти из аккаунта ]  ← red btn   │
└──────────────────────────────────────┘
```

- Avatar: `UILabel` with initials in a circular `UIView` with `AppColor.elevated` background
- Info rows: each a horizontal `UIStackView` with an SF Symbol icon + text label
- Logout button: `AppColor.accent` (red) background, white title "Выйти из аккаунта"
- Tapping logout calls `viewModel.logout()`

### ProfileCoordinator

```swift
final class ProfileCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    let navigationController: UINavigationController
    private let container: AppContainer
    private let onLogout: () -> Void

    init(navigationController: UINavigationController,
         container: AppContainer,
         onLogout: @escaping () -> Void)

    func start() {
        let vm = ProfileViewModel(auth: container.auth)
        vm.onLogoutCompleted = { [weak self] in self?.onLogout() }
        let vc = ProfileViewController(viewModel: vm)
        navigationController.setViewControllers([vc], animated: false)
    }
}
```

---

## Logout Flow

1. User taps "Выйти из аккаунта" in `ProfileViewController`
2. `viewModel.logout()` → `auth.logout()` → `vm.onLogoutCompleted?()`
3. `ProfileCoordinator.onLogout()` fires
4. `MainTabCoordinator.handleLogout()` is called (no-op — `auth.logout()` already called)
5. `auth.isAuthenticatedPublisher` emits `false`
6. `AppCoordinator` receives the event and switches to the auth flow

> **Note:** `auth.logout()` is called inside `ProfileViewModel.logout()`. `MainTabCoordinator.handleLogout()` does not need to call it again. The `onLogout` callback exists purely to let the coordinator chain know the action has occurred.

---

## Testing

### OrdersViewModelTests

Mock: `MockOrdersService: OrdersServicing` with `CurrentValueSubject<[Order], Never>`.

Tests:
1. `test_initialOrders_populatedFromService` — orders sync-initialized from `service.orders`
2. `test_orders_updatesWhenServiceEmits` — publisher emits new array, `viewModel.orders` updates (drain main queue)
3. `test_isEmpty_trueWhenNoOrders` — `orders = []` → `isEmpty == true`
4. `test_isEmpty_falseWhenOrdersExist` — `orders = [order]` → `isEmpty == false`

### ProfileViewModelTests

Mock: `MockAuthService: AuthServicing` (already exists or mirrors `MockCartService` pattern).

Tests:
1. `test_profile_exposesCurrentUser` — `auth.currentUser` surfaced as `vm.profile`
2. `test_logout_callsAuthLogout` — `vm.logout()` → `mockAuth.logoutCalled == true`
3. `test_logout_firesOnLogoutCompleted` — `vm.onLogoutCompleted` called after `vm.logout()`

---

## Error Handling

None required. All three screens are read-only. Orders and Profile use in-memory services that never fail. Promotions is static.

---

## Out of Scope

- Order detail screen (tap to expand)
- Editable profile fields
- Real promotion images (SF Symbols used as placeholders throughout)
- Backend integration
