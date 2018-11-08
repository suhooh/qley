import Foundation
import SwiftyJSON

struct Coordinate {
    let latitude: Float?
    let longitude: Float?

    init?(_ json: JSON) {
        self.latitude = json["latitude"].float
        self.longitude = json["longitude"].float
    }
}
