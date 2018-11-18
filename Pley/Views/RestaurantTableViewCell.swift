import UIKit
import Cosmos

class RestaurantTableViewCell: UITableViewCell {
    static let reuseIdentifier = String(describing: RestaurantTableViewCell.self)

    @IBOutlet weak var mainImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var ratingView: CosmosView!
    @IBOutlet weak var reviewLabel: UILabel!
    @IBOutlet weak var priceAndCagegoriesLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!

    func setUp(with restaurant: Restaurant, index: Int) {
        nameLabel.text = "\(index + 1). \(restaurant.name)"
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
            mainImageView.contentMode = .scaleAspectFill
            mainImageView.kf.setImage(with: imageUrl)
        } else {
            mainImageView.contentMode = .center
            mainImageView.image = UIImage(named: "flower")
        }
    }

    // prevent background color from being cleared
    override func setSelected(_ selected: Bool, animated: Bool) {
        let color = ratingView.superview?.backgroundColor
        super.setSelected(selected, animated: animated)
        if selected { ratingView.superview?.backgroundColor = color }
    }

    // prevent background color from being cleared
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        let color = ratingView.superview?.backgroundColor
        super.setHighlighted(highlighted, animated: animated)
        if highlighted { ratingView.superview?.backgroundColor = color }
    }
}
