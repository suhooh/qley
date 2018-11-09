import Foundation
import SwiftyJSON
import MapKit

struct Coordinate {
    let latitude: Double?
    let longitude: Double?

    var clLocation2D: CLLocationCoordinate2D? {
        guard let latitude = latitude, let longitude = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init?(_ json: JSON) {
        self.latitude = json["latitude"].double
        self.longitude = json["longitude"].double
    }
}
