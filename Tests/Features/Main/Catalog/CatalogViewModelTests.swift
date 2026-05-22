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
