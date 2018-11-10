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

    var viewModel: BusinessViewModel? {
        didSet {
            bindViewModel()
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

    func bindViewModel() {
        guard let viewModel = viewModel else { return }

        searchBar.rx.text.orEmpty
            .bind(to: viewModel.searchText)
            .disposed(by: disposeBag)

        searchBar.rx.searchButtonClicked
            .subscribe { _ in
                self.searchBarResignFirstResponder()
            }
            .disposed(by: disposeBag)

        searchBar.rx.cancelButtonClicked
            .subscribe { _ in
                self.searchBar.text = nil
                self.searchBarResignFirstResponder()
                self.searchBar.setShowsCancelButton(false, animated: true)
            }
            .disposed(by: disposeBag)

        searchBar.rx.textDidBeginEditing
            .subscribe { _ in
                self.searchBar.setShowsCancelButton(true, animated: true)
            }
            .disposed(by: disposeBag)

        // Merge two observables to show one of the latest event between autocompletions or businesses
        Observable.of(
            viewModel.autocompletes.map { MultipleSectionModel.AutocompleteSection(items: $0.map { s in SectionItem.AutocompleteSectionItem(text: s) }) },
            viewModel.businesses.map { MultipleSectionModel.BusinessesSection(items: $0.map { b in SectionItem.BusinessesSectionItem(business: b)}) }
            )
            .merge()
            .map { data -> [MultipleSectionModel] in
                guard let item = data.items.first else { return [] }
                // return [AutocompleteSection, BusinessesSection] all the time
                switch item {
                case .AutocompleteSectionItem(_):
                    return [data, .BusinessesSection(items: [])]
                case .BusinessesSectionItem(_):
                    return [.AutocompleteSection(items: []), data]
                }
            }
            .bind(to: tableView.rx.items(dataSource: BusinessTableViewController.dataSource))
            .disposed(by: disposeBag)

// RxDataSources - two different cells by each section
//        Observable.combineLatest(viewModel.autocompletes, viewModel.businesses) { (autocompletes, businesses) in
//            [ .AutocompleteSection(items: autocompletes.map { .AutocompleteSectionItem(text: $0) }),
//              .BusinessesSection(items: businesses.map { .BusinessesSectionItem(business: $0) }) ]
//            }
//            .bind(to: tableView.rx.items(dataSource: BusinessTableViewController.dataSource))
//            .disposed(by: disposeBag)

// two types of cells with single section
//        Observable.of(
//            viewModel.autocompletes.map { MultipleSectionModel.AutocompleteSection(items: $0.map { s in .AutocompleteSectionItem(text: s) }) },
//            viewModel.businesses.map { MultipleSectionModel.BusinessesSection(items: $0.map { b in .BusinessesSectionItem(business: b)}) }
//            )
//            .merge()
//            .map { $0.items }
//            .bind(to: tableView.rx.items) { tableView, index, item in
//                let indexPath = IndexPath(item: index, section: 0)
//                switch item {
//                case let .AutocompleteSectionItem(text):
//                    let cell = tableView.dequeueReusableCell(withIdentifier: AutocompletTableViewCell.reuseIdendifier, for: indexPath) as! AutocompletTableViewCell
//                    cell.setUp(with: text)
//                    return cell
//                case let .BusinessesSectionItem(business):
//                    let cell = tableView.dequeueReusableCell(withIdentifier: BusinessTableViewCell.reuseIdendifier, for: indexPath) as! BusinessTableViewCell
//                    cell.setUp(with: business, index: indexPath.row)
//                    return cell
//                }
//            }
//            .disposed(by: disposeBag)
    }

    func searchBarResignFirstResponder() {
        self.searchBar.resignFirstResponder()
        (self.searchBar.value(forKey: "cancelButton") as? UIButton)?.isEnabled = true
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
        if drawer.drawerPosition != .open { searchBarResignFirstResponder() }
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
