import UIKit

class BusinessTableViewCell: UITableViewCell {
    static let reuseIdendifier = String(describing: BusinessTableViewCell.self)
    
    @IBOutlet weak var mainImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
}
