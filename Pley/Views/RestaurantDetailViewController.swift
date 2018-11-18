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

    override var previewActionItems: [UIPreviewActionItem] {
        var actions: [UIPreviewAction] = []
        if let phone = restaurant?.phone, let number = URL(string: "tel://" + phone) {
            let call = UIPreviewAction(title: "Call for a Reservation", style: .default) { _, _ in
                UIApplication.shared.open(number)
            }
            actions.append(call)
        }
        actions.append(UIPreviewAction(title: "Close", style: .destructive) { _, _ in })
        return actions
    }
}
