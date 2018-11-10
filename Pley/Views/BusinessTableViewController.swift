import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import Pulley

class BusinessTableViewController: UIViewController {

    private struct Constants {
        static let searchBarHeight: CGFloat = 63.0
        static let partialRevealedDrawerHeight: CGFloat = 264.0
        static let autocompletedRowHeight: CGFloat = 60
        static let businessRowHeight: CGFloat = 110
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

        // search bar UI
        searchBar.barTintColor = .clear
        searchBar.backgroundImage = UIImage()
        (searchBar.value(forKey: "searchField") as? UITextField)?.textColor = .black
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(bounceDrawer), userInfo: nil, repeats: false)
    }
    @objc fileprivate func bounceDrawer() { self.pulleyViewController?.bounceDrawer() }

    func bindView(with viewModel: BusinessViewModel) {
        searchBar.rx.text.orEmpty
            .bind(to: viewModel.searchText)
            .disposed(by: disposeBag)

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

        Observable.combineLatest(viewModel.autocompletes, viewModel.businesses) { (autocompletes, businesses) in
            [ .AutocompleteSection(items: autocompletes.map { .AutocompleteSectionItem(text: $0) }),
              .BusinessesSection(items: businesses.map { .BusinessesSectionItem(business: $0) }) ]
            }
            .bind(to: tableView.rx.items(dataSource: BusinessTableViewController.dataSource))
            .disposed(by: disposeBag)

//        viewModel.businesses
//            .bind(to: tableView.rx.items(cellIdentifier: BusinessTableViewCell.reuseIdendifier,
//                                         cellType: BusinessTableViewCell.self)) { index, element, cell in
//                cell.setUp(with: element, index: index)
//            }
//            .disposed(by: disposeBag)

//        viewModel.autocompletes
//            .bind(to: tableView.rx.items) { tableView, index, element in
//                let cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
//                cell.textLabel?.text = element
//                return cell
//            }
//            .disposed(by: disposeBag)
    }

}

// MARK: - UITableViewDelegate
extension BusinessTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.section == 0 ? Constants.autocompletedRowHeight : Constants.businessRowHeight
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

// MARK: - RxTableViewSectionedReloadDataSource

extension BusinessTableViewController {

    static var dataSource: RxTableViewSectionedReloadDataSource<MultipleSectionModel> {
        return RxTableViewSectionedReloadDataSource<MultipleSectionModel>(
            configureCell: { (dataSource, tableView, indexPath, _) in
                switch dataSource[indexPath] {
                case let .AutocompleteSectionItem(text):
                    let cell = tableView.dequeueReusableCell(withIdentifier: AutocompletTableViewCell.reuseIdendifier, for: indexPath) as! AutocompletTableViewCell
                    cell.setUp(with: text)
                    return cell
                case let .BusinessesSectionItem(business):
                    let cell = tableView.dequeueReusableCell(withIdentifier: BusinessTableViewCell.reuseIdendifier, for: indexPath) as! BusinessTableViewCell
                    cell.setUp(with: business, index: indexPath.row)
                    return cell
                }
        })
    }

}

// MARK: - MultipleSectionModel
// type definition for multiple tableview data source

enum MultipleSectionModel {
    case AutocompleteSection(items: [SectionItem])
    case BusinessesSection(items: [SectionItem])
}

enum SectionItem {
    case AutocompleteSectionItem(text: String)
    case BusinessesSectionItem(business: Business)
}

extension MultipleSectionModel: SectionModelType {
    typealias Item = SectionItem

    var items: [SectionItem] {
        switch self {
        case .AutocompleteSection(items: let items): return items.map { $0 }
        case .BusinessesSection(items: let items):   return items.map { $0 }
        }
    }

    init(original: MultipleSectionModel, items: [Item]) {
        switch original {
        case .AutocompleteSection(items: let items): self = .AutocompleteSection(items: items)
        case .BusinessesSection(items: let items):   self = .BusinessesSection(items: items)
        }
    }
}
