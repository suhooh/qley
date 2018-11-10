import UIKit
import RxSwift
import RxCocoa
import Pulley

class BusinessTableViewController: UIViewController {

    private struct Constants {
        static let searchBarHeight: CGFloat = 63.0
        static let partialRevealedDrawerHeight: CGFloat = 264.0
    }

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var headerSectionHeightConstraint: NSLayoutConstraint!

    var viewModel: BusinessViewModel! {
        didSet {
            bindView(with: viewModel)
            bindTableView(with: viewModel)
        }
    }

    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.pulleyViewController?.delegate = self

        // transparent search bar
        searchBar.barTintColor = .clear
        searchBar.backgroundImage = UIImage()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(bounceDrawer), userInfo: nil, repeats: false)
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
                (self.searchBar.value(forKey: "cancelButton") as? UIButton)?.isEnabled = true
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
            .bind(to: tableView.rx.items(cellIdentifier: BusinessTableViewCell.reuseIdendifier,
                                         cellType: BusinessTableViewCell.self)) { index, element, cell in
                cell.setUp(with: element, index: index)
            }
            .disposed(by: disposeBag)

//        viewModel.autocompletes
//            .bind(to: tableView.rx.items) { tableView, index, element in
//                let cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
//                cell.textLabel?.text = element
//                return cell
//            }
//            .disposed(by: disposeBag)

    }

    @objc fileprivate func bounceDrawer() {
        self.pulleyViewController?.bounceDrawer()
    }
}

// MARK: - PulleyDrawerViewControllerDelegate

extension BusinessTableViewController: PulleyDrawerViewControllerDelegate {
    // For devices with a bottom safe area ( e.g. iPhone X )

    func collapsedDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat {
        return Constants.searchBarHeight + (pulleyViewController?.currentDisplayMode == .drawer ? bottomSafeArea : 0.0)
    }

    func partialRevealDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat {
        return Constants.partialRevealedDrawerHeight + (pulleyViewController?.currentDisplayMode == .drawer ? bottomSafeArea : 0.0)
    }

    func drawerPositionDidChange(drawer: PulleyViewController, bottomSafeArea: CGFloat) {
        headerSectionHeightConstraint.constant = Constants.searchBarHeight + (drawer.drawerPosition == .collapsed ? bottomSafeArea : 0.0)
        // tableView.isScrollEnabled = drawer.drawerPosition == .open || drawer.currentDisplayMode == .panel
    }
}
