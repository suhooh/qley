import UIKit
import RxSwift
import RxCocoa
import RxCoreLocation
import MapKit
import RxMKMapView
import Kingfisher

class BusinessMapViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!

    var viewModel: BusinessViewModel? {
        didSet {
            bindViewModel()
        }
    }
    private let disposeBag = DisposeBag()
    private let locationManager = CLLocationManager()

    override func viewDidLoad() {
        super.viewDidLoad()

        checkLocationAuthorizationStatus()
        locationManager.startUpdatingLocation()
    }

    func checkLocationAuthorizationStatus() {
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            mapView.showsUserLocation = true
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
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

        viewModel.output.annotations
            .asDriver(onErrorJustReturn: [])
            .drive(mapView.rx.annotations)
            .disposed(by: disposeBag)

        locationManager.rx.didUpdateLocations
            .debug("MAP:: didUpdateLocations")
            .subscribe(onNext: { _ in })
            .disposed(by: disposeBag)

        locationManager.rx.didChangeAuthorization
            .debug("MAP:: didChangeAuthorization")
            .subscribe(onNext: { event in print(event) })
            .disposed(by: disposeBag)

        locationManager.rx.location
            .debug("MAP:: location")
            .subscribe(onNext: { location in
                guard let location = location else { return }
                self.centerMapOnLocation(location: location)
            })
            .disposed(by: disposeBag)
    }

    // TODO: remove
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate,
                                                  latitudinalMeters: 1000,
                                                  longitudinalMeters: 1000)
        mapView.setRegion(coordinateRegion, animated: true)
    }
}

// MARK: - MKMapViewDelegate

extension BusinessMapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !annotation.isKind(of: MKUserLocation.self) else { return nil }

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
