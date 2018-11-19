import UIKit

class AutocompletTableViewCell: UITableViewCell {
    static let reuseIdentifier = String(describing: AutocompletTableViewCell.self)

    @IBOutlet weak var recentImageView: UIImageView!
    @IBOutlet weak var completedLabel: UILabel!

    func setUp(with autocomplete: Autocomplete) {
        let isAutocomplete = autocomplete.type == .autocomplete

        recentImageView.isHidden = isAutocomplete
        completedLabel.text = autocomplete.text
        completedLabel.font = UIFont.systemFont(ofSize: 18,
                                                weight: isAutocomplete ? .semibold : .medium)
    }
}
