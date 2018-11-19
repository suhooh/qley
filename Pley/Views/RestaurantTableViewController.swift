import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import Pulley

class RestaurantTableViewController: RxBaseViewController<RestaurantViewModel>,
                                     UITableViewDelegate, PulleyDrawerViewControllerDelegate {
    static let identifier = String(describing: RestaurantTableViewController.self)

    struct Constants {
        static let partialRevealedDrawerHeight: CGFloat = 264.0
        fileprivate static let searchBarHeight: CGFloat = 63.0
        fileprivate static let autocompletedRowHeight: CGFloat = 60
        fileprivate static let restaurantRowHeight: CGFloat = 110
    }

    enum TableSection: Int {
        case autocompletes = 0
        case restaurants = 1

        static var autocompletesIndex: Int { return autocompletes.rawValue }
        static var restaurantsIndex: Int { return restaurants.rawValue }
    }

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var headerSectionHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableViewBottomConstraint: NSLayoutConstraint!

    private let searchString = Variable<String>("")
    var restaurants: [Restaurant] = []
    private var needsAutocomplete: Bool = true
    private var previousDrawerPosition: PulleyPosition?
    var selectedIndex: Int = 0 {
        didSet {
            if pulleyViewController?.drawerPosition != .partiallyRevealed {
                pulleyViewController?.setDrawerPosition(position: .partiallyRevealed, animated: true)
            }
            let indexPath = IndexPath(row: selectedIndex, section: TableSection.restaurantsIndex)
            let cell = tableView.cellForRow(at: indexPath)

            tableView.scrollToRow(at: indexPath, at: .top, animated: true)

            cell?.setSelected(true, animated: false)
            DispatchQueue.main.asyncAfter(
                deadline: DispatchTime.now() + Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC),
                execute: { cell?.setSelected(false, animated: true) })
        }
    }
    private lazy var noItemLabel: UILabel = {
        let noItem: UILabel = UILabel()
        noItem.font = UIFont.boldSystemFont(ofSize: 16)
        noItem.textAlignment = .center
        noItem.textColor = .gray
        noItem.text = "No restaurants available in this area."
        return noItem
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        pulleyViewController?.delegate = self
        previousDrawerPosition = pulleyViewController?.initialDrawerPosition

        // search bar UI
        searchBar.barTintColor = .clear
        searchBar.backgroundImage = UIImage()
        (searchBar.value(forKey: "searchField") as? UITextField)?.textColor = .black
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
//            self?.pulleyViewController?.bounceDrawer()
//        }
    }

    override func bind(viewModel: RestaurantViewModel) {
        super.bind(viewModel: viewModel)

        bindSearchBar(viewModel)
        bindTableView(viewModel)
    }

    private func bindSearchBar(_ viewModel: RestaurantViewModel) {
        searchBar.rx.text.orEmpty.asDriver()
            .drive(searchString)
            .disposed(by: disposeBag)

        searchString.asObservable()
            .subscribe(onNext: { [unowned self] in self.searchBar.text = $0 })
            .disposed(by: disposeBag)

        searchString.asObservable()
            .map { [unowned self] in SearchTerm($0, autocomplete: self.needsAutocomplete) }
            .bind(to: viewModel.input.searchTerm)
            .disposed(by: disposeBag)

        searchBar.rx.searchButtonClicked
            .do(onNext: { [unowned self] _ in
                self.searchBarResignFirstResponder()
            })
            .bind(to: viewModel.input.doSearch)
            .disposed(by: disposeBag)

        searchBar.rx.cancelButtonClicked
            .subscribe { [unowned self] _ in
                self.searchBarResignFirstResponder()
                self.searchBar.setShowsCancelButton(false, animated: true)
            }
            .disposed(by: disposeBag)

        searchBar.rx.textDidBeginEditing
            .subscribe { [unowned self] _ in
                self.searchBar.setShowsCancelButton(true, animated: true)
            }
            .disposed(by: disposeBag)
    }

    private func bindTableView(_ viewModel: RestaurantViewModel) {
        // RxDataSources - Merge two observables to show one of the latest event between autocompletions or restaurants
        Observable.of(
            viewModel.output.autocompletes
                .map { MultipleSectionModel.autocompleteSection(items: $0.map { autocomplete in
                    SectionItem.autocompleteItem(autocomplete: autocomplete)
                })
            },
            viewModel.output.restaurants
                .map { MultipleSectionModel.restaurantSection(items: $0.map { bsn in
                    SectionItem.restaurantItem(restaurant: bsn)
                })
            })
            .merge()
            .map { data -> [MultipleSectionModel] in
                guard let item = data.items.first else { return [] }
                switch item {
                // returns [AutocompleteSection, RestaurantSection] format
                case .autocompleteItem: return [data, .restaurantSection(items: [])]
                case .restaurantItem: return [.autocompleteSection(items: []), data]
                }
            }
            .bind(to: tableView.rx.items(dataSource: RestaurantTableViewController.dataSource))
            .disposed(by: disposeBag)

        Observable
            .zip(tableView.rx.itemSelected, tableView.rx.modelSelected(SectionItem.self))
            // consume restaurant selection
            .do(onNext: { [unowned self] indexPath, model in
                self.tableView.deselectRow(at: indexPath, animated: true)
                switch model {
                case .restaurantItem:
                    if let pulley = self.pulleyViewController as? RestaurantViewController {
                        pulley.shareUserTableSelection(index: indexPath.row)
                    }
                default: break
                }
            })
            // consume autocomplete selection
            .map { _, model -> String? in
                switch model {
                case let .autocompleteItem(autocomplete): return autocomplete.text
                case .restaurantItem: return nil
                }
            }
            .filter { $0 != nil }
            .do(onNext: { [unowned self] str in
                self.needsAutocomplete = false
                self.searchString.value = str ?? ""
                self.needsAutocomplete = true
                self.searchBarResignFirstResponder()
            })
            .map { _ in }
            .bind(to: viewModel.input.doSearch)
            .disposed(by: disposeBag)

        viewModel.output.restaurants
            .subscribe(onNext: { [unowned self] data in
                self.restaurants = data
                self.displayNoItems(data.first == nil)
            })
            .disposed(by: disposeBag)

        viewModel.output.autocompletes
            .subscribe(onNext: { [unowned self] _ in self.displayNoItems(false) })
            .disposed(by: disposeBag)
    }

    private func searchBarResignFirstResponder() {
        self.searchBar.resignFirstResponder()
        (self.searchBar.value(forKey: "cancelButton") as? UIButton)?.isEnabled = true
    }

    private func displayNoItems(_ isOn: Bool) {
        self.tableView.backgroundView = isOn ? noItemLabel : nil
        self.tableView.separatorStyle = isOn ? .none : .singleLine
    }

// MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.section == TableSection.autocompletesIndex
            ? Constants.autocompletedRowHeight
            : Constants.restaurantRowHeight
    }

// MARK: - PulleyDrawerViewControllerDelegate
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
        if previousDrawerPosition == .open &&
            drawer.drawerPosition != .open &&
            searchBar.isFirstResponder {
            searchBarResignFirstResponder()
        }

        previousDrawerPosition = drawer.drawerPosition
    }
}

// MARK: - RxTableViewSectionedReloadDataSource

extension RestaurantTableViewController {
    private static var dataSource: RxTableViewSectionedReloadDataSource<MultipleSectionModel> {
        return RxTableViewSectionedReloadDataSource<MultipleSectionModel>(
            configureCell: { (dataSource, tableView, indexPath, _) in
                switch dataSource[indexPath] {
                case let .autocompleteItem(autocomplete):
                    guard let cell = tableView.dequeueReusableCell(
                        withIdentifier: AutocompletTableViewCell.reuseIdentifier,
                        for: indexPath) as? AutocompletTableViewCell
                        else { return UITableViewCell() }
                    cell.setUp(with: autocomplete)
                    return cell
                case let .restaurantItem(restaurant):
                    guard let cell = tableView.dequeueReusableCell(
                        withIdentifier: RestaurantTableViewCell.reuseIdentifier,
                        for: indexPath) as? RestaurantTableViewCell
                        else { return UITableViewCell() }
                    cell.setUp(with: restaurant, index: indexPath.row)
                    return cell
                }
        })
    }
}

// MARK: - MultipleSectionModel & SectionItem
// type wrapper definition for multiple tableview data source

enum SectionItem {
    case autocompleteItem(autocomplete: Autocomplete)
    case restaurantItem(restaurant: Restaurant)
}

enum MultipleSectionModel {
    case autocompleteSection(items: [SectionItem])
    case restaurantSection(items: [SectionItem])
}

extension MultipleSectionModel: SectionModelType {
    typealias Item = SectionItem

    var items: [SectionItem] {
        switch self {
        case .autocompleteSection(items: let items): return items.map { $0 }
        case .restaurantSection(items: let items):   return items.map { $0 }
        }
    }

    init(original: MultipleSectionModel, items: [Item]) {
        switch original {
        case .autocompleteSection(items: let items): self = .autocompleteSection(items: items)
        case .restaurantSection(items: let items):   self = .restaurantSection(items: items)
        }
    }
}
