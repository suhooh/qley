import Foundation
import MapKit

class BusinessAnnotation: NSObject, MKAnnotation {
    let name: String
    var title: String?
    var subtitle: String? { return name }
    let coordinate: CLLocationCoordinate2D

    init(name: String, coordinate: CLLocationCoordinate2D) {
        self.name = name
        self.coordinate = coordinate
        super.init()
    }
}
