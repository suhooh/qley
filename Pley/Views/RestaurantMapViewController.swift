import UIKit
import RxSwift
import RxCocoa
import RxCoreLocation
import MapKit
import RxMKMapView
import Kingfisher
import Pulley

protocol RestaurantMapViewProotocl: class {
    func restaurantMapViewDrawRoute(to: Restaurant)
}

class RestaurantMapViewController: RxBaseViewController<RestaurantViewModel>,
                                   MKMapViewDelegate, PulleyPrimaryContentControllerDelegate,
                                   RestaurantMapViewProotocl {
    static let identifier = String(describing: RestaurantMapViewController.self)

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var searchThisAreaButton: UIButton!
    @IBOutlet weak var userTrackButtonView: UIView!
    @IBOutlet weak var userControlViewBottomConstraint: NSLayoutConstraint!

    private var mapChangedFromUserInteraction = false
    private var properBottomConstraint: CGFloat = 0.0
    private var routeOverlay: MKOverlay? {
        willSet {
            deleteRouteOnMap()
        }
    }
    var selectedIndex: Int = 0 {
        didSet {
            deleteRouteOnMap()
            for annotation in mapView.annotations {
                if let restaurant = annotation as? RestaurantAnnotation, restaurant.number == selectedIndex + 1 {
                    mapView.selectAnnotation(restaurant, animated: true)
                    if !mapView.annotations(in: mapView.visibleMapRect).contains(restaurant) {
                        showAnnotationsInVisibleRegion(offset: self.properBottomConstraint)
                    }
                    return
                }
            }
        }
    }
    private lazy var locationManager = CLLocationManager()
    private lazy var trackButton: MKUserTrackingButton = MKUserTrackingButton(mapView: mapView)

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.register(NumberAnnotationView.self,
                         forAnnotationViewWithReuseIdentifier: NumberAnnotationView.reuseIdentifier)
        checkLocationAuthorizationStatus()
    }

    private func checkLocationAuthorizationStatus() {
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            trackUserLocation()
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }

    override func bind(viewModel: RestaurantViewModel) {
        super.bind(viewModel: viewModel)

        mapView.rx
            .setDelegate(self)
            .disposed(by: disposeBag)

        Observable
            .combineLatest(mapView.rx.region.asObservable(), viewModel.input.searchTerm.asObservable())
            .do(onNext: { [unowned self] _, term in
                self.searchThisAreaButton.isHidden = !(self.mapChangedFromUserInteraction && !term.isEmpty)
            })
            .map { [unowned self] region, _ in
                return SearchArea(coordinate: region.center, radius: self.mapView.currentRadius)
            }
            .bind(to: viewModel.input.searchArea)
            .disposed(by: disposeBag)

        mapView.rx.regionWillChangeAnimated
            .subscribe(onNext: { [unowned self] _ in
                self.mapChangedFromUserInteraction = self.mapViewRegionDidChangeFromUserInteraction()
            })
            .disposed(by: disposeBag)

        mapView.rx.didSelectAnnotationView
            .subscribe(onNext: { [unowned self] annotationView in
                if let pulley = self.pulleyViewController as? RestaurantViewController,
                    let annotation = annotationView.annotation as? RestaurantAnnotation {
                    pulley.shareUserMapSelection(index: annotation.number - 1)
                }
                self.deleteRouteOnMap()
            })
            .disposed(by: disposeBag)

        searchThisAreaButton.rx.tap
            .do(onNext: { [unowned self] _ in self.searchThisAreaButton.isHidden = true })
            .bind(to: viewModel.input.doSearch)
            .disposed(by: disposeBag)

        viewModel.output.annotations
            .do(onNext: { [unowned self] annotations in
                self.deleteRouteOnMap()
                self.mapView.showAnnotations(annotations, animated: true)
                self.showAnnotationsInVisibleRegion(offset: self.properBottomConstraint)
            })
            .drive(mapView.rx.annotations)
            .disposed(by: disposeBag)

        viewModel.output.searchTermChanged
            .subscribe(onNext: { [unowned self] in
                self.deleteRouteOnMap()
                self.mapView.removeAnnotations(self.mapView.annotations) })
            .disposed(by: disposeBag)

        locationManager.rx.didUpdateLocations
            .subscribe(onNext: { [unowned self] _, locations in
                guard let location = locations.last else { return }
                DispatchQueue.once { [weak self] in self?.centerMapOnLocation(location: location) }
            })
            .disposed(by: disposeBag)

        locationManager.rx.didChangeAuthorization
            .subscribe({ [unowned self] _ in
                if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
                    self.trackUserLocation()
                }
            })
            .disposed(by: disposeBag)
    }

    private func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate,
                                                  latitudinalMeters: 2000,
                                                  longitudinalMeters: 2000)
        mapView.setRegion(coordinateRegion, animated: true)
    }

    private func trackUserLocation() {
        mapView.showsUserLocation = true
        userTrackButtonView.addSubview(trackButton)
        userTrackButtonView.isHidden = false
        locationManager.startUpdatingLocation()
    }

    private func showAnnotationsInVisibleRegion(offset: CGFloat,
                                                annotations: [MKAnnotation]? = nil,
                                                includingMe: Bool = false) {
        var ans: [MKAnnotation] = mapView.annotations
        if let annotations = annotations {
            ans = annotations
        }
        if ans.isEmpty || (ans.count == 1 && ans[0].isEqual(mapView.userLocation) && !includingMe) { return }

        var totalMapRect = MKMapRect.null
        for annotation in ans {
            if annotation.isEqual(mapView.userLocation), !includingMe { continue }
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

// MARK: - MKMapViewDelegate

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !annotation.isKind(of: MKUserLocation.self) else { return nil }

        let view = mapView.dequeueReusableAnnotationView(withIdentifier: NumberAnnotationView.reuseIdentifier) ??
            MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: NumberAnnotationView.reuseIdentifier)
        view.annotation = annotation
        return view
    }

// MARK: - PulleyPrimaryContentControllerDelegate

    func drawerPositionDidChange(drawer: PulleyViewController, bottomSafeArea: CGFloat) {
        if drawer.drawerPosition == .open {
            mapChangedFromUserInteraction = false
        }
    }

    func drawerChangedDistanceFromBottom(drawer: PulleyViewController, distance: CGFloat, bottomSafeArea: CGFloat) {
        let trackButtonBottomDistance: CGFloat = 8.0
        let partialRevealedDrawerHeight: CGFloat = RestaurantTableViewController.Constants.partialRevealedDrawerHeight

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

// MARK: - showRouteOnMap
    func showRouteOnMap(pickupCoordinate: CLLocationCoordinate2D, destinationCoordinate: CLLocationCoordinate2D) {
        deleteRouteOnMap()

        let sourcePlacemark = MKPlacemark(coordinate: pickupCoordinate, addressDictionary: nil)
        let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
        let sourceAnnotation = MKPointAnnotation()
        if let location = sourcePlacemark.location {
            sourceAnnotation.coordinate = location.coordinate
        }

        let destinationPlacemark = MKPlacemark(coordinate: destinationCoordinate, addressDictionary: nil)
        let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
        let destinationAnnotation = MKPointAnnotation()
        if let location = destinationPlacemark.location {
            destinationAnnotation.coordinate = location.coordinate
        }

        let directionRequest = MKDirections.Request()
        directionRequest.source = sourceMapItem
        directionRequest.destination = destinationMapItem
        directionRequest.transportType = .automobile

        let directions = MKDirections(request: directionRequest)

        directions.calculate { [weak self] response, _ -> Void in
            guard let self = self, let response = response else { return }
            let route = response.routes[0]
            self.routeOverlay = route.polyline
            self.mapView.addOverlay(self.routeOverlay!, level: MKOverlayLevel.aboveRoads)
            // let rect = route.polyline.boundingMapRect
            // self.mapView.setRegion(MKCoordinateRegion(rect), animated: true)
        }

        self.showAnnotationsInVisibleRegion(offset: properBottomConstraint,
                                            annotations: [sourceAnnotation, destinationAnnotation],
                                            includingMe: true)
    }

    func deleteRouteOnMap() {
        guard let routeOverlay = routeOverlay else { return }
        mapView.removeOverlay(routeOverlay)
    }

// MARK: - MKMapViewDelegate
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)

        renderer.strokeColor = UIColor(red: 17.0/255.0, green: 147.0/255.0, blue: 255.0/255.0, alpha: 1)
        renderer.lineWidth = 5.0
        return renderer
    }

// MARK: - MKMapViewDelegate
    func restaurantMapViewDrawRoute(to target: Restaurant) {
        for annotation in mapView.annotations {
            if let restaurant = annotation as? RestaurantAnnotation, restaurant.id == target.id {
                mapView.selectAnnotation(restaurant, animated: true)
                showRouteOnMap(pickupCoordinate: mapView.userLocation.coordinate,
                               destinationCoordinate: restaurant.coordinate)
                return
            }
        }
    }
}
