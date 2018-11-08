import Foundation
import SwiftyJSON

struct Business {
    let id: String
    let name: String
    let reviewCount: Int

    let rating: Float?
    let alias: String?
    let isClosed: Bool?
    let url: String?
    let distance: Float?
    let location: Location?
    let price: String?
    let phone: String?
    let displayPhone: String?
    let imageUrl: String?
    let coordinates: Coordinate?
    let categories: [Category]?
    let transactions: [String]?

    init?(json: JSON) {
        guard let id = json["id"].string, let name = json["name"].string else { return nil }

        self.id = id
        self.name = name

        // Optionals
        self.reviewCount = json["review_count"].int ?? 0
        self.rating = json["rating"].float
        self.alias =  json["alias"].string
        self.isClosed = json["is_closed"].bool
        self.url = json["url"].string
        self.distance = json["distance"].float
        self.location = Location(json["location"])
        self.price = json["price"].string
        self.phone = json["phone"].string
        self.displayPhone = json["display_phone"].string
        self.imageUrl = json["image_url"].string
        self.coordinates = Coordinate(json["coordinates"])
        self.categories = json["categories"].array?.compactMap(Category.init)
        self.transactions = json["transactions"].array?.compactMap(String.init)
    }
}
