import Foundation
import MapKit

class BusinessAnnotation: NSObject, MKAnnotation {
    let number: Int
    let name: String
    let category: String
    var title: String? { return name }
    var subtitle: String? { return category }
    let coordinate: CLLocationCoordinate2D

    init(number: Int, name: String, category: String, coordinate: CLLocationCoordinate2D) {
        self.number = number
        self.name = name
        self.category = category
        self.coordinate = coordinate
        super.init()
    }
}
