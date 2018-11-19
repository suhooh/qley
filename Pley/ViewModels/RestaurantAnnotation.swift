import Foundation
import MapKit

class RestaurantAnnotation: NSObject, MKAnnotation {
    let id: String
    let number: Int
    let name: String
    let category: String

    var title: String? { return name }
    var subtitle: String? { return category }
    let coordinate: CLLocationCoordinate2D

    init(id: String, number: Int, name: String, category: String, coordinate: CLLocationCoordinate2D) {
        self.id = id
        self.number = number
        self.name = name
        self.category = category
        self.coordinate = coordinate
        super.init()
    }
}
