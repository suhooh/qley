import Foundation

struct Restaurant {
    let id: String
    let name: String
    let rating: Double?
    let distance: Float?
    let reviewCount: Int?
    let price: String?
    let categories: [String]?
    let location: String?
    let imageUrl: String?
    let phone: String?

    init(id: String, name: String, rating: Double?, distance: Float?, reviewCount: Int?,
         price: String?, categories: [String]?, location: String?, imageUrl: String?, phone: String?) {
        self.id = id
        self.name = name
        self.rating = rating
        self.distance = distance
        self.reviewCount = reviewCount
        self.price = price
        self.categories = categories
        self.location = location
        self.imageUrl = imageUrl
        self.phone = phone
    }
}
