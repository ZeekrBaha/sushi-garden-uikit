struct Product: Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    let categoryId: String
    let weightGrams: Int
    let price: Int          // whole rubles
    let imageName: String
    let description: String
}
