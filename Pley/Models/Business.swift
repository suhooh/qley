import Foundation
import SwiftyJSON

struct Business {
    let id: String
    let rating: Int
    let price: String
    let phone: String
    let alias: String
    let isClosed: Bool
    let categories: [Category]
    let reviewCount: Int
    let name: String
    let url: String
    let coordinates: Coordinate
    let imageUrl: String
    let location: Location
    let distance: Float
    let transactions: [String]

    init?(json: JSON) {
        guard
            let id = json["id"].string,
            let rating = json["rating"].int,
            let price = json["price"].string,
            let phone = json["phone"].string,
            let alias = json["alias"].string,
            let isClosed = json["is_closed"].bool,
            let categoriesData = json["categories"].array,
            let reviewCount = json["review_count"].int,
            let name = json["name"].string,
            let url = json["url"].string,
            let coordinates = Coordinate(json["coordinates"]),
            let imageUrl = json["image_url"].string,
            let location = Location(json["location"]),
            let distance = json["distance"].float,
            let transactionsData = json["transactions"].array
            else {
                return nil
        }

        self.id = id
        self.rating = rating
        self.price = price
        self.phone = phone
        self.alias = alias
        self.isClosed = isClosed
        self.categories = categoriesData.compactMap(Category.init)
        self.reviewCount = reviewCount
        self.name = name
        self.url = url
        self.coordinates = coordinates
        self.imageUrl = imageUrl
        self.location = location
        self.distance = distance
        self.transactions = transactionsData.compactMap(String.init)
    }
}
