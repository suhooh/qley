import UIKit
import Pulley
import RxSwift
import DSGradientProgressView

class RestaurantViewController: PulleyViewController, RxBaseViewControllerProtocol {

    private let viewModel = RestaurantViewModel()
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

        guard let mapViewController = primaryContentViewController as? RestaurantMapViewController,
            let tableViewController = drawerContentViewController as? RestaurantTableViewController
            else { return }
        mapViewController.viewModel = viewModel
        tableViewController.viewModel = viewModel

        bind(viewModel: viewModel)

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
        viewModel.output.networking.asObservable()
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
}
