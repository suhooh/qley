import UIKit

class AutocompletTableViewCell: UITableViewCell {
    static let reuseIdendifier = String(describing: AutocompletTableViewCell.self)

    @IBOutlet weak var completedLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func setUp(with text: String) {
        completedLabel.text = text
    }
}
