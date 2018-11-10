import UIKit
import Cosmos

class BusinessTableViewCell: UITableViewCell {
    static let reuseIdendifier = String(describing: BusinessTableViewCell.self)
    
    @IBOutlet weak var mainImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var ratingView: CosmosView!
    @IBOutlet weak var reviewLabel: UILabel!
    @IBOutlet weak var priceAndCagegoriesLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func setUp(with business: Business, index: Int) {
        nameLabel.text = "\(index + 1). \(business.name)"
        ratingView.rating = business.rating

        let distance = business.distance == nil ? "" : String(format: " \u{2022} %0.2fkm", business.distance! / 1000 )
        reviewLabel.text = "\(business.reviewCount) reviews\(distance)"

        let price = business.price.isEmpty ? "" : "\(business.price) \u{2022} "
        priceAndCagegoriesLabel.text = "\(price)\(business.categories.compactMap({ $0.title }).joined(separator: ", "))"

        if let address = business.location?.displayAddress, !address.isEmpty {
            addressLabel.text = address.joined(separator: ", ")
        }

        if let imageUrlString = business.imageUrl, let imageUrl = URL(string: imageUrlString) {
            mainImageView.contentMode = .scaleAspectFill
            mainImageView.kf.setImage(with: imageUrl)
        } else {
            mainImageView.contentMode = .center
            mainImageView.image = UIImage(named: "flower")
        }
    }
}
