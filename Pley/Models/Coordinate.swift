import Foundation
import MapKit

struct Coordinate: Codable {
    let latitude: Double?
    let longitude: Double?

    var clLocation2D: CLLocationCoordinate2D? {
        guard let latitude = latitude, let longitude = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
