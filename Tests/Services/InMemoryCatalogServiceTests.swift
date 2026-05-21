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
