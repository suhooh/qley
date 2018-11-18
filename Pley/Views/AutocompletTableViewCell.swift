import UIKit

class AutocompletTableViewCell: UITableViewCell {
    static let reuseIdentifier = String(describing: AutocompletTableViewCell.self)

    @IBOutlet weak var completedLabel: UILabel!

    func setUp(with text: String) {
        completedLabel.text = text
    }
}
