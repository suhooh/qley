import UIKit
import RxSwift
import RxCocoa
import MapKit
import RxMKMapView
import Kingfisher

class BusinessMapViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!

    var viewModel: BusinessViewModel? {
        didSet {
            bindViewModel()
            // TODO: remove
            centerMapOnLocation(location: viewModel!.location)
        }
    }
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func bindViewModel() {
        guard let viewModel = viewModel else { return }

        mapView.rx
            .setDelegate(self)
            .disposed(by: disposeBag)

        //        mapView.rx.region
        //            .subscribe(onNext: { region in
        //                print("Map region is now \(region)")
        //            })
        //            .disposed(by: disposeBag)

        mapView.rx.region
            .bind(to: viewModel.coordinateRegion)
            .dispose()

        mapView.rx.regionDidChangeAnimated
            .subscribe(onNext: { _ in
                print("Map region changed")
            })
            .disposed(by: disposeBag)

        viewModel.annotations
            .asDriver(onErrorJustReturn: [])
            .drive(mapView.rx.annotations)
            .disposed(by: disposeBag)
    }

    // TODO: remove
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
        mapView.setRegion(coordinateRegion, animated: true)
    }
}

// MARK: - MKMapViewDelegate

extension BusinessMapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseIdentifier = "annotationView"
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier) ??
            MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
        // prevent annotation clustering
        view.displayPriority = .required
        view.annotation = annotation
        //        view.canShowCallout = true
        return view
    }
}
