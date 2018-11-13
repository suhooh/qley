import MapKit

class NumberAnnotationView: MKMarkerAnnotationView {
    static let reuseIdendifier = String(describing: NumberAnnotationView.self)

    override var annotation: MKAnnotation? {
        willSet {
            guard let business = newValue as? BusinessAnnotation else { return }

            displayPriority = .required // prevent annotation clustering
            glyphText = String(business.number)
            titleVisibility = .adaptive
            subtitleVisibility = .adaptive
        }
    }
}
