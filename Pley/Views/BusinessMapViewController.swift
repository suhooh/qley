import UIKit
import RxSwift
import RxCocoa
import RxCoreLocation
import MapKit
import RxMKMapView
import Kingfisher
import Pulley

class BusinessMapViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var userTrackButtonView: UIView!
    @IBOutlet var userTrackButtonViewBottomConstraint: NSLayoutConstraint!

    var viewModel: BusinessViewModel? {
        didSet {
            bindViewModel()
        }
    }
    private let disposeBag = DisposeBag()
    private let locationManager = CLLocationManager()
    private var trackButton: MKUserTrackingButton?

    override func viewDidLoad() {
        super.viewDidLoad()

        checkLocationAuthorizationStatus()
        locationManager.startUpdatingLocation()
    }

    func checkLocationAuthorizationStatus() {
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            mapView.showsUserLocation = true
            addMapTrackingButton()
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }

    func addMapTrackingButton() {
        trackButton = MKUserTrackingButton(mapView: mapView)
        if let btn = trackButton {
            userTrackButtonView.addSubview(btn)
            userTrackButtonView.isHidden = false
        }
    }

    @objc func centerMapOnUserButtonClicked() {
        mapView.setUserTrackingMode(MKUserTrackingMode.follow, animated: true)
    }

    func bindViewModel() {
        guard let viewModel = viewModel else { return }

        mapView.rx
            .setDelegate(self)
            .disposed(by: disposeBag)

        mapView.rx.region
            .do(onNext: { region in
                print("Map region is now \(region)")
            })
            .bind(to: viewModel.input.coordinateRegion)
            .disposed(by: disposeBag)

//        mapView.rx.regionDidChangeAnimated
//            .subscribe(onNext: { _ in
//                print("Map region changed")
//            })
//            .disposed(by: disposeBag)

        viewModel.output.annotations
            .asDriver(onErrorJustReturn: [])
            .drive(mapView.rx.annotations)
            .disposed(by: disposeBag)

        locationManager.rx.didUpdateLocations
            .subscribe(onNext: { [unowned self] _, locations in
                guard let location = locations.last else { return }
                DispatchQueue.once { self.centerMapOnLocation(location: location) }
            })
            .disposed(by: disposeBag)

        locationManager.rx.didChangeAuthorization
            .debug("MAP:: didChangeAuthorization")
            .subscribe(onNext: { event in print(event) })
            .disposed(by: disposeBag)
    }

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
        //view.canShowCallout = true
        return view
    }
}

// MARK: - PulleyPrimaryContentControllerDelegate

extension BusinessMapViewController: PulleyPrimaryContentControllerDelegate {
    func drawerChangedDistanceFromBottom(drawer: PulleyViewController, distance: CGFloat, bottomSafeArea: CGFloat) {
        let trackButtonBottomDistance: CGFloat = 8.0
        let partialRevealedDrawerHeight: CGFloat = 264.0

        guard drawer.currentDisplayMode == .drawer else {
            userTrackButtonViewBottomConstraint.constant = trackButtonBottomDistance
            return
        }

        userTrackButtonViewBottomConstraint.constant = trackButtonBottomDistance +
            (distance <= partialRevealedDrawerHeight + bottomSafeArea ? distance : partialRevealedDrawerHeight)
    }
}
