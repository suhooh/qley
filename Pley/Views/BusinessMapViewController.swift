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
    @IBOutlet weak var userTrackButtonViewBottomConstraint: NSLayoutConstraint!

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
    }

    func checkLocationAuthorizationStatus() {
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            trackUserLocation()
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }

    func bindViewModel() {
        guard let viewModel = viewModel else { return }

        mapView.rx
            .setDelegate(self)
            .disposed(by: disposeBag)

        mapView.rx.region
            .map { [unowned self] region in
                return (region, self.mapView.currentRadius)
            }
            .bind(to: viewModel.input.regionAndRadius)
            .disposed(by: disposeBag)

        viewModel.output.annotations
            .asDriver(onErrorJustReturn: [])
            .do(onNext: { annotations in
                self.mapView.showAnnotations(annotations, animated: true)
            })
            .drive(mapView.rx.annotations)
            .disposed(by: disposeBag)

        locationManager.rx.didUpdateLocations
            .subscribe(onNext: { [unowned self] _, locations in
                guard let location = locations.last else { return }
                DispatchQueue.once { self.centerMapOnLocation(location: location) }
            })
            .disposed(by: disposeBag)

        locationManager.rx.didChangeAuthorization
            .subscribe({ [unowned self] _ in
                self.trackUserLocation()
            })
            .disposed(by: disposeBag)
    }

    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate,
                                                  latitudinalMeters: 1000,
                                                  longitudinalMeters: 1000)
        mapView.setRegion(coordinateRegion, animated: true)
    }

    func trackUserLocation() {
        mapView.showsUserLocation = true
        trackButton = MKUserTrackingButton(mapView: mapView)
        if let btn = trackButton {
            userTrackButtonView.addSubview(btn)
            userTrackButtonView.isHidden = false
        }
        locationManager.startUpdatingLocation()
    }

    func showAnnotationsInVisibleRegion(offset: CGFloat) {
        var totalMapRect = MKMapRect.null
        for annotation in mapView.annotations {
            let annotationPoint = MKMapPoint(annotation.coordinate)
            let mapRect = MKMapRect.init(x: annotationPoint.x, y: annotationPoint.y, width: 0.1, height: 0.1)
            totalMapRect = totalMapRect.union(mapRect)
        }
        mapView.setVisibleMapRect(totalMapRect,
                                  edgePadding: UIEdgeInsets(top: 30, left: 30, bottom: 30 + offset, right: 30),
                                  animated: true)
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

        let properBottomConstraint = trackButtonBottomDistance +
            (distance <= partialRevealedDrawerHeight + bottomSafeArea ? distance : partialRevealedDrawerHeight)
        userTrackButtonViewBottomConstraint.constant = properBottomConstraint
        if mapView.annotations.count > 1 {
            showAnnotationsInVisibleRegion(offset: properBottomConstraint)
        }
    }
}
