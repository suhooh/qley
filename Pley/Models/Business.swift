import Foundation

struct Business: Codable {
    let id: String
    let name: String

    let reviewCount: Int?
    let rating: Double?
    let price: String?
    let categories: [Category]?
    let alias: String?
    let isClosed: Bool?
    let url: String?
    let distance: Float?
    let location: Location?
    let phone: String?
    let displayPhone: String?
    let imageUrl: String?
    let coordinates: Coordinate?
    let transactions: [String]?
}
