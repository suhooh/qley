import UIKit
import MapKit
import Cosmos

class RestaurantDetailViewController: UIViewController {
    static let identifier = String(describing: RestaurantDetailViewController.self)

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var ratingView: CosmosView!
    @IBOutlet weak var reviewLabel: UILabel!
    @IBOutlet weak var priceAndCagegoriesLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var phoneLabel: UILabel!

    weak var mapDelegate: RestaurantMapViewProotocl?
    var restaurant: Restaurant?

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let restaurant = restaurant else { return }

        let gradient = CAGradientLayer()
        gradient.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 120)
        gradient.colors = [UIColor.black.cgColor, UIColor.clear.cgColor]
        photoImageView.layer.insertSublayer(gradient, at: 0)

        setUp(with: restaurant)
    }

    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: true)
    }

    private func setUp(with restaurant: Restaurant?) {
        guard let restaurant = restaurant else { return }
        nameLabel.text = restaurant.name

        phoneLabel.text = restaurant.phone

        ratingView.rating = restaurant.rating ?? 0

        let distance = restaurant.distance == nil ? ""
            : String(format: " \u{2022} %0.2fkm", restaurant.distance! / 1000 )
        reviewLabel.text = "\(restaurant.reviewCount ?? 0) reviews\(distance)"

        var priceString = ""
        if let price = restaurant.price, !price.isEmpty {
            priceString = "\(price) \u{2022} "
        }
        var categoryString = ""
        if let categories = restaurant.categories {
            categoryString = categories.compactMap { $0 }.joined(separator: ", ")
        }
        priceAndCagegoriesLabel.text = "\(priceString)\(categoryString)"

        addressLabel.text = restaurant.location

        if let imageUrlString = restaurant.imageUrl, let imageUrl = URL(string: imageUrlString) {
            photoImageView.contentMode = .scaleAspectFill
            photoImageView.kf.setImage(with: imageUrl)
        } else {
            photoImageView.contentMode = .center
            photoImageView.image = UIImage(named: "flower")
        }
    }

    override var previewActionItems: [UIPreviewActionItem] {
        var actions: [UIPreviewAction] = []
        if let phone = restaurant?.phone, !phone.isEmpty, let number = URL(string: "tel://" + phone) {
            let call = UIPreviewAction(title: "Call " + phone, style: .default) { _, _ in
                UIApplication.shared.open(number)
            }
            actions.append(call)
        }
        if let restaurant = restaurant,
            let mapView = mapDelegate,
            CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            let call = UIPreviewAction(title: "See the Route", style: .default) { _, _ in
                mapView.restaurantMapViewDrawRoute(to: restaurant)
            }
            actions.append(call)
        }
        // actions.append(UIPreviewAction(title: "Close", style: .destructive) { _, _ in })
        return actions
    }
}
