import Foundation
import MapKit

struct SearchArea {
    private let coordinate: CLLocationCoordinate2D
    let radius: Double

    var latitude: Double { return coordinate.latitude }
    var longitude: Double { return coordinate.longitude}

    init(coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(), radius: Double = 0.0) {
        self.coordinate = coordinate
        self.radius = radius
    }
}
