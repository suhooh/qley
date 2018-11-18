import MapKit

class NumberAnnotationView: MKMarkerAnnotationView {
    static let reuseIdentifier = String(describing: NumberAnnotationView.self)

    override var annotation: MKAnnotation? {
        willSet {
            guard let annotation = newValue as? RestaurantAnnotation else { return }

            displayPriority = .required // prevent annotation clustering
            glyphText = String(annotation.number)
            titleVisibility = .adaptive
            subtitleVisibility = .adaptive
            markerTintColor = #colorLiteral(red: 0.8254979253, green: 0.1416396797, blue: 0.1354189217, alpha: 1)
        }
    }
}
