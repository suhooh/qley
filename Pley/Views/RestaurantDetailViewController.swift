import UIKit

class RestaurantDetailViewController: UIViewController {
    static let identifier = String(describing: RestaurantDetailViewController.self)

    @IBOutlet weak var nameLabel: UILabel!

    var restaurant: Restaurant?

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let restaurant = restaurant else { return }

        nameLabel.text = restaurant.name
    }

    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
}
