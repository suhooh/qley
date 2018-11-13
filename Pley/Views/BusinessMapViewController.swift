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
    @IBOutlet weak var searchThisAreaButton: UIButton!
    @IBOutlet weak var userTrackButtonView: UIView!
    @IBOutlet weak var userControlViewBottomConstraint: NSLayoutConstraint!
    private var mapChangedFromUserInteraction = false

    var viewModel: BusinessViewModel? {
        didSet {
            bindViewModel()
        }
    }
    private let disposeBag = DisposeBag()
    private let locationManager = CLLocationManager()
    private var trackButton: MKUserTrackingButton?

    private var properBottomConstraint: CGFloat = 0.0

    var selectedIndex: Int = 0 {
        didSet {
            for annotation in mapView.annotations {
                if let ann = annotation as? BusinessAnnotation, ann.number == selectedIndex + 1 {
                    mapView.selectAnnotation(ann, animated: true)
                    return
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.register(NumberAnnotationView.self,
                         forAnnotationViewWithReuseIdentifier: NumberAnnotationView.reuseIdendifier)
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

        Observable
            .combineLatest(mapView.rx.region.asObservable(), viewModel.input.searchText.asObservable())
            .do(onNext: { _, term in
                self.searchThisAreaButton.isHidden = !(self.mapChangedFromUserInteraction && !term.isEmpty)
            })
            .map { region, _ in return (region, self.mapView.currentRadius) }
            .bind(to: viewModel.input.regionAndRadius)
            .disposed(by: disposeBag)

        mapView.rx.regionWillChangeAnimated
            .subscribe(onNext: { _ in
                self.mapChangedFromUserInteraction = self.mapViewRegionDidChangeFromUserInteraction()
            })
            .disposed(by: disposeBag)

        mapView.rx.didSelectAnnotationView
            .subscribe(onNext: { annotationView in
                if let pulley = self.pulleyViewController as? BusinessViewController,
                    let annotation = annotationView.annotation as? BusinessAnnotation {
                    pulley.shareUserMapSelection(index: annotation.number - 1)
                }
            })
            .disposed(by: disposeBag)

        searchThisAreaButton.rx.tap
            .do(onNext: { _ in self.searchThisAreaButton.isHidden = true })
            .bind(to: viewModel.input.doSearch)
            .disposed(by: disposeBag)

        viewModel.output.annotations
            .asDriver(onErrorJustReturn: [])
            .do(onNext: { annotations in
                self.mapView.showAnnotations(annotations, animated: true)
                self.showAnnotationsInVisibleRegion(offset: self.properBottomConstraint)
            })
            .drive(mapView.rx.annotations)
            .disposed(by: disposeBag)

        locationManager.rx.didUpdateLocations
            .subscribe(onNext: { _, locations in
                guard let location = locations.last else { return }
                DispatchQueue.once { self.centerMapOnLocation(location: location) }
            })
            .disposed(by: disposeBag)

        locationManager.rx.didChangeAuthorization
            .subscribe({ _ in self.trackUserLocation() })
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
        let ans = mapView.annotations
        if ans.isEmpty || (ans.count == 1 && ans[0].isEqual(mapView.userLocation)) { return }

        var totalMapRect = MKMapRect.null
        for annotation in ans {
            if annotation.isEqual(mapView.userLocation) { continue }
            let annotationPoint = MKMapPoint(annotation.coordinate)
            let mapRect = MKMapRect.init(x: annotationPoint.x, y: annotationPoint.y, width: 0.1, height: 0.1)
            totalMapRect = totalMapRect.union(mapRect)
        }
        mapView.setVisibleMapRect(totalMapRect,
                                  edgePadding: UIEdgeInsets(top: 30, left: 30, bottom: 30 + offset, right: 30),
                                  animated: true)
    }

    private func mapViewRegionDidChangeFromUserInteraction() -> Bool {
        let view = mapView.subviews[0]
        if let gestureRecognizers = view.gestureRecognizers {
            for recognizer in gestureRecognizers where ( recognizer.state == .began || recognizer.state == .ended ) {
                return true
            }
        }
        return false
    }
}

// MARK: - MKMapViewDelegate

extension BusinessMapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !annotation.isKind(of: MKUserLocation.self) else { return nil }

        let view = mapView.dequeueReusableAnnotationView(withIdentifier: NumberAnnotationView.reuseIdendifier) ??
            MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: NumberAnnotationView.reuseIdendifier)
        view.annotation = annotation
        return view
    }
}

// MARK: - PulleyPrimaryContentControllerDelegate

extension BusinessMapViewController: PulleyPrimaryContentControllerDelegate {
    func drawerPositionDidChange(drawer: PulleyViewController, bottomSafeArea: CGFloat) {
        if drawer.drawerPosition == .open {
            mapChangedFromUserInteraction = false
        }
    }

    func drawerChangedDistanceFromBottom(drawer: PulleyViewController, distance: CGFloat, bottomSafeArea: CGFloat) {
        let trackButtonBottomDistance: CGFloat = 8.0
        let partialRevealedDrawerHeight: CGFloat = BusinessTableViewController.Constants.partialRevealedDrawerHeight

        guard drawer.currentDisplayMode == .drawer else {
            userControlViewBottomConstraint.constant = trackButtonBottomDistance
            return
        }

        properBottomConstraint = trackButtonBottomDistance +
            (distance <= partialRevealedDrawerHeight + bottomSafeArea ? distance : partialRevealedDrawerHeight)
        userControlViewBottomConstraint.constant = properBottomConstraint
        if mapView.annotations.count > 1 {
            showAnnotationsInVisibleRegion(offset: properBottomConstraint)
        }
    }
}
