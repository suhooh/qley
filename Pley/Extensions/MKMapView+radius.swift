import MapKit

extension MKMapView {

    var currentRadius: Double {
        let centerLocation = CLLocation(latitude: self.centerCoordinate.latitude,
                                        longitude: self.centerCoordinate.longitude)
        let topCenterCoordinate = self.topCenterCoordinate()
        let topCenterLocation = CLLocation(latitude: topCenterCoordinate.latitude,
                                           longitude: topCenterCoordinate.longitude)
        return centerLocation.distance(from: topCenterLocation)
    }

    func topCenterCoordinate() -> CLLocationCoordinate2D {
        return self.convert(CGPoint(x: self.frame.size.width / 2.0, y: 0), toCoordinateFrom: self)
    }
}
