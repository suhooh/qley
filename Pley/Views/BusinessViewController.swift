import UIKit
import RxSwift
import RxCocoa
import MapKit
import RxMKMapView
import Kingfisher

class BusinessViewController: UIViewController {

    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tableView: UITableView!

    private var viewModel: BusinessViewModel!
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel = BusinessViewModel()
        bindView(with: viewModel)
        bindMapView(with: viewModel)
        bindTableView(with: viewModel)

        // TODO: remove
        centerMapOnLocation(location: viewModel.location)
    }

    private func bindView(with viewModel: BusinessViewModel) {
        searchTextField.rx.text.orEmpty
            .bind(to: viewModel.searchText)
            .disposed(by: disposeBag)

//        viewModel.businesses
//            .map { "\($0.count) \($0.description)" }
//            .bind(to: logTextView.rx.text)
//            .disposed(by: disposeBag)
    }

    func bindTableView(with viewModel: BusinessViewModel) {
        viewModel.businesses
            .bind(to: tableView.rx.items) { (tableView: UITableView, index: Int, element: Business) in
                let indexPath = IndexPath(item: index, section: 0)
                guard let cell = tableView.dequeueReusableCell(withIdentifier: BusinessTableViewCell.reuseIdendifier, for: indexPath) as? BusinessTableViewCell else {
                    return UITableViewCell()
                }
                cell.nameLabel.text = element.name
                cell.mainImageView.kf.setImage(with: URL(string: element.imageUrl!)!)
                return cell
            }
            .disposed(by: disposeBag)
    }

    func bindMapView(with viewModel: BusinessViewModel) {
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

extension BusinessViewController: MKMapViewDelegate {
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
