# Sushi Garden (UIKit) — Design Spec

**Date:** 2026-05-20
**Status:** Approved (design) — pending implementation plan
**Source design:** Figma "Error Nil. Apps" — `wOK1MMzuJZF3pIOZhGHpY9`, node `1-4`
**Repo:** `~/Desktop/llm-ai-projects/sushi-garden-uikit`

## 1. Summary

A dark-theme **sushi food-delivery iOS app** rebuilt from the Figma design as a
**fresh, pure-UIKit + Combine** application targeting **iOS 17**, using a
**native UIKit Coordinator** navigation architecture and **MVVM** with
`@Published`/Combine binding. All data and auth are **mocked in-memory behind
protocols**, so a real backend can be dropped in later without touching the UI.

This is a deliberate, separate project from the existing SwiftUI-in-UIKit build
at `sushi-garden-ios`; nothing depends on it.

## 2. Goals / Non-goals

**Goals**
- Reproduce every screen in the Figma (full app).
- Pure UIKit view layer, programmatic Auto Layout, no storyboards.
- Combine-driven MVVM; coordinators own all navigation.
- In-memory mock services behind protocols; fully unit-testable.
- TDD: failing test first, then minimal implementation.

**Non-goals (v1)**
- Real networking / Firebase / persistence (protocols leave the door open).
- Payment processing, push notifications, real maps geocoding beyond a static map.
- iPad / landscape optimization (iPhone portrait, 430pt reference width).

## 3. Decisions (locked)

| Area | Decision |
|---|---|
| Basis | Fresh new project; reuse nothing from `sushi-garden-ios` |
| Stack | UIKit + Combine, iOS 17.0 min, Swift 5.9+ |
| UI | Programmatic, no storyboards, Auto Layout |
| Navigation | Native UIKit Coordinator pattern |
| Binding | MVVM, ViewModel `@Published` state, VC `.sink` to render |
| Scope | Full app — all Figma screens |
| Data | All in-memory behind protocols (mock) |
| Tooling | XcodeGen (`project.yml`) + SPM |

## 4. Architecture

### 4.1 Coordinators
- `Coordinator` protocol: `var childCoordinators: [Coordinator] { get set }`, `func start()`.
  Flow coordinators own a `UINavigationController`.
- **`AppCoordinator`** — owns the `UIWindow`. Subscribes to
  `AuthServicing.isAuthenticated` (Combine). Logged out → installs
  `AuthCoordinator`; on success → swaps window root to `MainTabCoordinator`;
  on logout → back to auth.
- **`AuthCoordinator`** — Splash → Register/Login (toggle). Auth-success
  output bubbles up via an `onAuthenticated` closure.
- **`MainTabCoordinator`** — builds a `UITabBarController` with five child
  coordinators, each with its own nav stack. Subscribes to
  `CartServicing.itemsPublisher` to update the **cart tab badge** reactively.
- **`CatalogCoordinator`** — Catalog → push Product Detail; "add" routes to
  `CartService`.
- **`CartCoordinator`** — Cart → push Checkout → place order → `OrdersService`,
  then switch to the Orders tab.
- `OrdersCoordinator`, `PromotionsCoordinator`, `ProfileCoordinator` — single-screen
  flows (room to grow).

### 4.2 MVVM + Combine binding
- ViewModel exposes `@Published private(set)` state and/or `AnyPublisher` outputs.
- ViewController owns `private var cancellables = Set<AnyCancellable>()`, `.sink`s
  to render, and calls plain VM methods for user intent (`didTapAdd()`).
- **Navigation events** are closures on the ViewModel that the coordinator
  assigns (e.g. `vm.onSelectProduct = { [weak self] in self?.showDetail($0) }`).
  No ViewController references another ViewController.

### 4.3 Dependency injection
- `AppContainer` builds the services once and exposes factory methods for
  coordinators and ViewModels. Coordinators receive the container (or the
  specific services they need) via initializer injection.

## 5. Project structure

```
Project/
  App/            AppDelegate, SceneDelegate
  Core/
    Coordinator/  Coordinator (protocol), AppCoordinator
    DI/           AppContainer
    Combine/      CancelBag, UIControl+Publisher helpers
  DesignSystem/   Colors, Typography(Sen), Spacing, Theme,
                  PrimaryButton, FormField, PriceChip, QuantityStepper, AssetImageView
  Resources/      Assets.xcassets, Fonts/, Strings (RU)
  Models/         Product, Category, AddOn, CartItem, Order, UserProfile, DeliveryAddress
  Services/
    Auth/         AuthServicing + InMemoryAuthService
    Catalog/      CatalogServicing + InMemoryCatalogService
    Cart/         CartServicing + InMemoryCartService
    Orders/       OrdersServicing + InMemoryOrdersService
    Validation/   FieldValidators
  Features/
    Auth/         AuthCoordinator; Splash, Register, Login (VC+VM each)
    Main/         MainTabCoordinator
      Catalog/    CatalogCoordinator; CatalogVC+VM; ProductDetailVC+VM;
                  cells: BannerCell, CategoryTabCell, ProductCell
      Cart/       CartCoordinator; CartVC+VM; CheckoutVC+VM (MapKit)
      Orders/     OrdersCoordinator; OrdersVC+VM
      Promotions/ PromotionsCoordinator; PromotionsVC+VM
      Profile/    ProfileCoordinator; ProfileVC+VM
Tests/            ViewModel + Service + Validator + Coordinator unit tests
UITests/          happy-path XCUITests
```

## 6. Design system (extracted from Figma)

**Colors**
- Background `#0F0F11`
- Surface / tab bar `#161616`
- Chip / elevated surface `#29282C`
- Accent red `#EC1A35` (primary CTA, delivery icon, badges)
- Text primary `#FFFFFF`, secondary `#6C6C74`, inactive `#4C4C4C`

**Typography** — "Sen" family (Regular 400, Bold 700). Observed sizes ≈
19 (price), 16.5 (product title), 15.8 (category tab / address), 14 (weight),
12 (delivery label), 11.8 (tab labels).

**Metrics** — card corner radius 12, banner radius 21, reference frame width 430pt,
tab bar ≈ 83pt incl. safe area, category bar ≈ 45pt, 2-column product grid.

## 7. Screens → controllers

| Figma | Controller | Notes |
|---|---|---|
| Splash (SUSHI logo) | `SplashViewController` | brief, then routes to auth |
| Регистрация / Войти | `RegisterViewController`/`LoginViewController` (+VM) | form, validation, red CTA, register/login toggle |
| Главная (Catalog) | `CatalogViewController` | compositional `UICollectionView` + diffable data source: address header, banner (paging), category strip, 2-col product grid |
| Product detail | `ProductDetailViewController` | hero image, name/weight/price, `QuantityStepper`, add-to-cart CTA |
| Корзина (Cart) | `CartViewController` | item rows w/ steppers, totals, checkout CTA |
| Checkout + address/map | `CheckoutViewController` | MapKit map, delivery address, order summary, place-order CTA |
| Заказы (Orders) | `OrdersViewController` | order list / status |
| Акции (Promotions) | `PromotionsViewController` | promo cards |
| Профиль (Profile) | `ProfileViewController` | avatar + options list |
| Tab bar (5) | `MainTabCoordinator` | Каталог / Заказы / Акции / Корзина / Профиль; active white, inactive gray |

## 8. Data layer (mock, in-memory)

- `AuthServicing` (+`InMemoryAuthService`): register/login validate against a
  seeded user; publishes `isAuthenticated` via Combine.
- `CatalogServicing` (+`InMemoryCatalogService`): hardcoded categories
  (Суши, Роллы, Горячие роллы, Салаты, WOK) and products matching the Figma
  (e.g. Айдахо маки 810₽, Осака маки 740₽, Хикари 620₽, Лос-Анджелес 707₽);
  filter by category.
- `CartServicing` (+`InMemoryCartService`): `@Published` items; add / remove /
  setQty; `totalCount`, `totalPrice`; `itemsPublisher` for badge + cart UI.
- `OrdersServicing` (+`InMemoryOrdersService`): place order from cart → orders list.
- `FieldValidators`: email, password, phone, non-empty.

Protocols make a real backend a drop-in replacement later.

## 9. Error handling & edge cases

- Auth: empty/invalid email, short password, empty required fields → surfaced
  as VM state, shown inline on the form.
- Empty cart state and empty catalog category render explicit empty states.
- Quantity stepper bounds: min 1, max (per product, default sensible cap).
- Mock images are bundled assets → no network failure paths in v1; `AssetImageView`
  falls back to a neutral placeholder when an asset is missing.

## 10. Testing strategy (TDD)

Failing test first, then minimal code, for:
- `FieldValidators` (all rules).
- Each service: cart math (add/remove/qty/totals), catalog filtering, auth flow.
- Each ViewModel: state transitions and intent handling.
- Coordinator wiring: `start()` sets the expected root / adds the child coordinator.

XCUITests (happy paths): register → catalog → add → cart → checkout → order placed;
login/register toggle.

## 11. Assumptions & known gaps

- **Fonts:** "Sen" is free (Google Fonts) and will be bundled. The Figma's
  **"Mugesta"** font appears only on the `+`/`−` stepper glyphs; it will be
  substituted with SF Symbols / system glyphs rather than sourcing a paid display
  font. *(Revisit if a Mugesta license/file is provided.)*
- **Assets:** product photos, banners, and the logo are raster fills in Figma and
  must be exported into `Assets.xcassets`. They can be pulled via the Figma MCP
  during implementation or supplied directly; neutral placeholders keep the build
  unblocked in the meantime.
- **Per-screen pixel spec:** the Catalog frame was read in full from the Figma
  JSON; Detail / Orders / Promotions / Profile / Checkout layouts will be rendered
  per-screen from Figma node thumbnails during implementation. The structure in
  this spec is firm; exact spacing is finalized per screen.
