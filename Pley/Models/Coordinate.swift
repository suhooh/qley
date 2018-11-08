import Foundation
import SwiftyJSON

struct Coordinate {
    let latitude: Float
    let longitude: Float

    init?(_ json: JSON) {
        guard
            let latitude = json["latitude"].float,
            let longitude = json["longitude"].float
            else {
                return nil
        }

        self.latitude = latitude
        self.longitude = longitude
    }
}
