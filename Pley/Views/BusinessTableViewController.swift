import UIKit
import RxSwift
import RxCocoa

class BusinessTableViewController: UIViewController {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!

    var viewModel: BusinessViewModel! {
        didSet {
            bindView(with: viewModel)
            bindTableView(with: viewModel)
        }
    }

    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        // transparent search bar
        searchBar.barTintColor = .clear
        searchBar.backgroundImage = UIImage()
    }

    func bindView(with viewModel: BusinessViewModel) {
        searchBar.rx.text.orEmpty
            .bind(to: viewModel.searchText)
            .disposed(by: disposeBag)

        //        viewModel.businesses
        //            .map { "\($0.count) \($0.description)" }
        //            .bind(to: logTextView.rx.text)
        //            .disposed(by: disposeBag)

        searchBar.rx.searchButtonClicked
            .subscribe { _ in
                self.searchBar.resignFirstResponder()
            }
            .disposed(by: disposeBag)

        searchBar.rx.cancelButtonClicked
            .subscribe { _ in
                self.searchBar.text = nil
                self.searchBar.resignFirstResponder()
                self.searchBar.setShowsCancelButton(false, animated: true)
            }
            .disposed(by: disposeBag)

        searchBar.rx.textDidBeginEditing
            .subscribe { _ in
                self.searchBar.setShowsCancelButton(true, animated: true)
            }
            .disposed(by: disposeBag)
    }

    func bindTableView(with viewModel: BusinessViewModel) {
        viewModel.businesses
            .bind(to: tableView.rx.items) { (tableView: UITableView, index: Int, element: Business) in
                let indexPath = IndexPath(item: index, section: 0)
                let cell = tableView.dequeueReusableCell(withIdentifier: BusinessTableViewCell.reuseIdendifier, for: indexPath) as! BusinessTableViewCell
                cell.setUp(with: element, index: index)
                return cell
            }
            .disposed(by: disposeBag)
    }
}
