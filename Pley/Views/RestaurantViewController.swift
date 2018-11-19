import UIKit
import Pulley
import RxSwift
import DSGradientProgressView

class RestaurantViewController: PulleyViewController, RxBaseViewControllerProtocol,
    UIViewControllerPreviewingDelegate {

    struct Constants {
        fileprivate static let preferredContentHeight: CGFloat = 500.0
    }

    var viewModel: RestaurantViewModel? {
        didSet {
            guard let viewModel = viewModel else { return }
            bind(viewModel: viewModel)
        }
    }
    private let disposeBag = DisposeBag()
    lazy var progressView: DSGradientProgressView = {
        let progress = DSGradientProgressView(frame: CGRect(origin: CGPoint(x: 0, y: 0),
                                                            size: CGSize(width: view.frame.width, height: 3)))
        progress.barColor = #colorLiteral(red: 0.3963322639, green: 0.6601038575, blue: 0.9536740184, alpha: 1)
        progress.isHidden = true
        view.addSubview(progress)
        return progress
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        animationDuration = 0.5

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillDisappear),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillAppear),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
    }

    func bind(viewModel: RestaurantViewModel) {
        guard let mapViewController = primaryContentViewController as? RestaurantMapViewController,
            let tableViewController = drawerContentViewController as? RestaurantTableViewController
            else { return }

        mapViewController.viewModel = viewModel
        tableViewController.viewModel = viewModel

        viewModel.output.isNetworking.asObservable()
            .subscribe(onNext: { [weak self] isNetworking in
                isNetworking ? self?.progressView.wait() : self?.progressView.signal()
            })
            .disposed(by: disposeBag)
    }

    @objc func keyboardWillAppear() {
        guard drawerPosition != .open else { return }
        setDrawerPosition(position: .open, animated: true)
    }

    @objc func keyboardWillDisappear() {
        setDrawerPosition(position: .partiallyRevealed, animated: true)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func shareUserMapSelection(index: Int) {
        guard let tableViewController = drawerContentViewController as? RestaurantTableViewController else { return }
        tableViewController.selectedIndex = index
    }

    func shareUserTableSelection(index: Int) {
        guard let mapViewController = primaryContentViewController as? RestaurantMapViewController else { return }
        mapViewController.selectedIndex = index
    }

    // 3D touch
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if self.traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: view)
        }
    }

    // MARK: - UIViewControllerPreviewingDelegate
    func previewingContext(_ previewingContext: UIViewControllerPreviewing,
                           viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let restaurantViewController = drawerContentViewController as? RestaurantTableViewController,
            let tableView = restaurantViewController.tableView,
            let indexPath = tableView.indexPathForRow(at: view.convert(location, to: tableView)),
            let cell = tableView.cellForRow(at: indexPath),
            let restaurantDetailViewController = UIStoryboard(name: "Main", bundle: nil)
                .instantiateViewController(withIdentifier: RestaurantDetailViewController.identifier)
                as? RestaurantDetailViewController else { return nil }

        previewingContext.sourceRect = tableView.convert(cell.frame, to: view)

        let restaurant = restaurantViewController.restaurants[indexPath.row]
        restaurantDetailViewController.restaurant = restaurant
        restaurantDetailViewController.preferredContentSize =
            CGSize(width: 0.0, height: Constants.preferredContentHeight)
        restaurantDetailViewController.mapDelegate = primaryContentViewController as? RestaurantMapViewController
        return restaurantDetailViewController
    }

    func previewingContext(_ previewingContext: UIViewControllerPreviewing,
                           commit viewControllerToCommit: UIViewController) {
        // show(viewControllerToCommit,sender: self)
    }
}
