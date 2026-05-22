import Foundation

struct Order: Identifiable, Equatable, Hashable {
    enum Status: String, Equatable { case placed, cooking, delivering, delivered }

    let id: String
    let items: [CartItem]
    let total: Int
    let createdAt: Date
    var status: Status
}
