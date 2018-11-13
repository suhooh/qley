import UIKit
import Pulley
import RxSwift

class BusinessViewController: PulleyViewController {

    private let viewModel = BusinessViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()

        animationDuration = 0.5

        guard let mapViewController = primaryContentViewController as? BusinessMapViewController,
            let tableViewController = drawerContentViewController as? BusinessTableViewController
            else { return }
        mapViewController.viewModel = viewModel
        tableViewController.viewModel = viewModel

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillDisappear),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillAppear),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
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
        guard let tableViewController = drawerContentViewController as? BusinessTableViewController else { return }
        tableViewController.selectedIndex = index
    }

    func shareUserTableSelection(index: Int) {
        guard let mapViewController = primaryContentViewController as? BusinessMapViewController else { return }
        mapViewController.selectedIndex = index
    }
}
