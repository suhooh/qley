import Foundation
import SwiftyJSON

struct BusinessSearchResponse {
    let total: Int
    let businesses: [Business]
    let region: Region?

    init() {
        total = 0
        businesses = []
        region = nil
    }

    init?(_ json: JSON) {
        guard
            let total = json["total"].int,
            let businessesData = json["businesses"].array,
            let region = Region(json["region"])
            else {
                return nil
        }

        self.total = total
        self.businesses = businessesData.compactMap(Business.init)
        self.region = region
    }
}
