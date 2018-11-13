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
    @IBOutlet weak var tableViewBottomConstraint: NSLayoutConstraint!

    var viewModel: BusinessViewModel? {
        didSet {
            bindViewModel()
        }
    }

    private let disposeBag = DisposeBag()

    var selectedIndex: Int = 0 {
        didSet {
            if pulleyViewController?.drawerPosition != .partiallyRevealed {
                pulleyViewController?.setDrawerPosition(position: .partiallyRevealed, animated: true)
            }
            let indexPath = IndexPath(row: selectedIndex, section: 1)
            let cell = tableView.cellForRow(at: indexPath)

            tableView.scrollToRow(at: indexPath, at: .top, animated: true)

            cell?.setSelected(true, animated: false)
            DispatchQueue.main.asyncAfter(
                deadline: DispatchTime.now() + Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC),
                execute: { cell?.setSelected(false, animated: true) })
        }
    }

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
//        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
//            self.pulleyViewController?.bounceDrawer()
//        }
    }

    func bindViewModel() {
        guard viewModel != nil else { return }

        bindSearchBar()
        bindTableView()
    }

    func bindSearchBar() {
        guard let viewModel = viewModel else { return }

        searchBar.rx.text.orEmpty
            .bind(to: viewModel.input.searchText)
            .disposed(by: disposeBag)

        searchBar.rx.searchButtonClicked
            .do(onNext: { _ in
                self.searchBarResignFirstResponder()
            })
            .bind(to: viewModel.input.doSearch)
            .disposed(by: disposeBag)

        searchBar.rx.cancelButtonClicked
            .subscribe { _ in
                self.searchBar.text = ""
                self.searchBarResignFirstResponder()
                self.searchBar.setShowsCancelButton(false, animated: true)
            }
            .disposed(by: disposeBag)

        searchBar.rx.textDidBeginEditing
            .subscribe { _ in
                self.searchBar.setShowsCancelButton(true, animated: true)
            }
            .disposed(by: disposeBag)
    }

    func bindTableView() {
        guard let viewModel = viewModel else { return }

        /// RxDataSources - Merge two observables to show one of the latest event between autocompletions or businesses
        Observable.of(
            viewModel.output.autocompletes
                .map { MultipleSectionModel.autocompleteSection(items: $0.map { str in
                    SectionItem.autocompleteSectionItem(text: str)
                })
            },
            viewModel.output.businesses
                .map { MultipleSectionModel.businessesSection(items: $0.map { bsn in
                    SectionItem.businessesSectionItem(business: bsn)
                })
            })
            .merge()
            .map { data -> [MultipleSectionModel] in
                guard let item = data.items.first else { return [] }
                switch item {
                // returns [AutocompleteSection, BusinessesSection] all the time
                case .autocompleteSectionItem: return [data, .businessesSection(items: [])]
                case .businessesSectionItem: return [.autocompleteSection(items: []), data]
                }
            }
            .bind(to: tableView.rx.items(dataSource: BusinessTableViewController.dataSource))
            .disposed(by: disposeBag)

        Observable
            .zip(tableView.rx.itemSelected, tableView.rx.modelSelected(SectionItem.self))
            // consume business selection
            .do(onNext: { indexPath, model in
                self.tableView.deselectRow(at: indexPath, animated: true)
                switch model {
                case .businessesSectionItem:
                    if let pulley = self.pulleyViewController as? BusinessViewController {
                        pulley.shareUserTableSelection(index: indexPath.row)
                    }
                default: break
                }
            })
            // consume autocomplete selection
            .map { _, model -> String? in
                switch model {
                case let .autocompleteSectionItem(text): return text
                case .businessesSectionItem: return nil
                }
            }
            .filter { $0 != nil }
            .do(onNext: { str in
                self.searchBar.text = str
                self.searchBarResignFirstResponder()
            })
            .map { _ in }
            .bind(to: viewModel.input.doSearch)
            .disposed(by: disposeBag)
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
        return Constants.partialRevealedDrawerHeight +
            (pulleyViewController?.currentDisplayMode == .drawer ? bottomSafeArea : 0.0)
    }

    func drawerPositionDidChange(drawer: PulleyViewController, bottomSafeArea: CGFloat) {
        headerSectionHeightConstraint.constant = Constants.searchBarHeight +
            (drawer.drawerPosition == .collapsed ? bottomSafeArea : 0.0)
        // tableView.isScrollEnabled = drawer.drawerPosition == .open || drawer.currentDisplayMode == .panel
        tableViewBottomConstraint.constant =
            drawer.drawerPosition == .partiallyRevealed
            ? view.frame.height - Constants.partialRevealedDrawerHeight - bottomSafeArea
            : 20
        if drawer.drawerPosition != .open { searchBarResignFirstResponder() }
    }
}

// MARK: - RxTableViewSectionedReloadDataSource

extension BusinessTableViewController {

    static var dataSource: RxTableViewSectionedReloadDataSource<MultipleSectionModel> {
        return RxTableViewSectionedReloadDataSource<MultipleSectionModel>(
            configureCell: { (dataSource, tableView, indexPath, _) in
                switch dataSource[indexPath] {
                case let .autocompleteSectionItem(text):
                    guard let cell = tableView.dequeueReusableCell(
                        withIdentifier: AutocompletTableViewCell.reuseIdendifier,
                        for: indexPath) as? AutocompletTableViewCell
                        else { return UITableViewCell() }
                    cell.setUp(with: text)
                    return cell
                case let .businessesSectionItem(business):
                    guard let cell = tableView.dequeueReusableCell(
                        withIdentifier: BusinessTableViewCell.reuseIdendifier,
                        for: indexPath) as? BusinessTableViewCell
                        else { return UITableViewCell() }
                    cell.setUp(with: business, index: indexPath.row)
                    return cell
                }
        })
    }

}

// MARK: - MultipleSectionModel
// type wrapper definition for multiple tableview data source

enum MultipleSectionModel {
    case autocompleteSection(items: [SectionItem])
    case businessesSection(items: [SectionItem])
}

enum SectionItem {
    case autocompleteSectionItem(text: String)
    case businessesSectionItem(business: Business)
}

extension MultipleSectionModel: SectionModelType {
    typealias Item = SectionItem

    var items: [SectionItem] {
        switch self {
        case .autocompleteSection(items: let items): return items.map { $0 }
        case .businessesSection(items: let items):   return items.map { $0 }
        }
    }

    init(original: MultipleSectionModel, items: [Item]) {
        switch original {
        case .autocompleteSection(items: let items): self = .autocompleteSection(items: items)
        case .businessesSection(items: let items):   self = .businessesSection(items: items)
        }
    }
}
