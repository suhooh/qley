import UIKit
import Pulley
import RxSwift

class BusinessViewController: PulleyViewController {

    private var viewModel: BusinessViewModel!
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel = BusinessViewModel()

        guard let mapViewController = primaryContentViewController as? BusinessMapViewController,
            let tableViewController = drawerContentViewController as? BusinessTableViewController
            else { return }
        mapViewController.viewModel = viewModel
        tableViewController.viewModel = viewModel
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillDisappear), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillAppear), name: UIResponder.keyboardWillShowNotification, object: nil)
    }

    @objc func keyboardWillAppear() {
        guard drawerPosition != .open else { return }
        setDrawerPosition(position: .open, animated: true)
    }

    @objc func keyboardWillDisappear() {
        setDrawerPosition(position: .partiallyRevealed, animated: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
}
