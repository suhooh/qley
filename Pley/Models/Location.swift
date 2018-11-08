import Foundation
import SwiftyJSON

struct Location {
    let address1: String
    let address2: String
    let address3: String
    let zipCode: String
    let city: String
    let state: String
    let country: String

    init?(_ json: JSON) {
        guard
            let address1 = json["address1"].string,
            let address2 = json["address2"].string,
            let address3 = json["address3"].string,
            let zipCode = json["zip_code"].string,
            let city = json["city"].string,
            let state = json["state"].string,
            let country = json["country"].string
            else {
                return nil
        }

        self.address1 = address1
        self.address2 = address2
        self.address3 = address3
        self.zipCode = zipCode
        self.city = city
        self.state = state
        self.country = country
    }
}

