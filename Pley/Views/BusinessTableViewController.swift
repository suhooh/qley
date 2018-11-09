import UIKit
import RxSwift

class BusinessTableViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!

    var viewModel: BusinessViewModel! {
        didSet {
            bindTableView(with: viewModel)
        }
    }

    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func bindTableView(with viewModel: BusinessViewModel) {
        viewModel.businesses
            .bind(to: tableView.rx.items) { (tableView: UITableView, index: Int, element: Business) in
                let indexPath = IndexPath(item: index, section: 0)
                guard let cell = tableView.dequeueReusableCell(withIdentifier: BusinessTableViewCell.reuseIdendifier, for: indexPath) as? BusinessTableViewCell else {
                    return UITableViewCell()
                }
                cell.nameLabel.text = element.name
                if let imageUrlString = element.imageUrl, let imageUrl = URL(string: imageUrlString) {
                    cell.mainImageView.kf.setImage(with: imageUrl)
                } else {
                    // TODO: default placeholder
                }
                return cell
            }
            .disposed(by: disposeBag)
    }
}
