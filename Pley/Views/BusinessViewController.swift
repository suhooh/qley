import UIKit
import RxSwift
import RxCocoa

class BusinessViewController: UIViewController {
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var logTextView: UITextView!

    private var viewModel: BusinessViewModel!
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel = BusinessViewModel()
        addBindsToViewModel(viewModel)
    }

    private func addBindsToViewModel(_ viewModel: BusinessViewModel) {
        searchTextField.rx.text.orEmpty
            .bind(to: viewModel.searchText)
            .disposed(by: disposeBag)

        viewModel.businesses
            .map { "\($0.count) \($0.description)" }
            .bind(to: logTextView.rx.text)
            .disposed(by: disposeBag)
    }
}
