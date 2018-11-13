import Foundation
import SwiftyJSON

struct Business {
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

    init?(json: JSON) {
        guard let id = json["id"].string, let name = json["name"].string else { return nil }

        self.id = id
        self.name = name
        self.reviewCount = json["review_count"].int
        self.rating = json["rating"].double
        self.price = json["price"].string
        self.categories = json["categories"].array?.compactMap(Category.init)

        // Optionals
        self.alias =  json["alias"].string
        self.isClosed = json["is_closed"].bool
        self.url = json["url"].string
        self.distance = json["distance"].float
        self.location = Location(json["location"])
        self.phone = json["phone"].string
        self.displayPhone = json["display_phone"].string
        self.imageUrl = json["image_url"].string
        self.coordinates = Coordinate(json["coordinates"])
        self.transactions = json["transactions"].array?.compactMap(String.init)
    }
}
