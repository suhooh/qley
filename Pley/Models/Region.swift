import Foundation
import SwiftyJSON

struct Region {
    let center: Coordinate

    init?(_ json: JSON) {
        guard let center = Coordinate(json["center"]) else { return nil }

        self.center = center
    }
}
