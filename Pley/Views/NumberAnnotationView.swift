import MapKit

class NumberAnnotationView: MKMarkerAnnotationView {
    static let reuseIdendifier = String(describing: NumberAnnotationView.self)

    override var annotation: MKAnnotation? {
        willSet {
            guard let annotation = newValue as? RestaurantAnnotation else { return }

            displayPriority = .required // prevent annotation clustering
            glyphText = String(annotation.number)
            titleVisibility = .adaptive
            subtitleVisibility = .adaptive
        }
    }
}
