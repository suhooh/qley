import Foundation
import SwiftyJSON

struct Location {
    let displayAddress: [String]?
    let address1: String?
    let address2: String?
    let address3: String?
    let zipCode: String
    let city: String
    let state: String
    let country: String

    init?(_ json: JSON) {
        guard
            let zipCode = json["zip_code"].string,
            let city = json["city"].string,
            let state = json["state"].string,
            let country = json["country"].string
            else {
                return nil
        }

        self.displayAddress = json["display_address"].array?.compactMap(String.init)
        self.address1 = json["address1"].string
        self.address2 = json["address2"].string
        self.address3 = json["address3"].string
        self.zipCode = zipCode
        self.city = city
        self.state = state
        self.country = country
    }
}
