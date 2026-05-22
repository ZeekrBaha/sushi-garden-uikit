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
