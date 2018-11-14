import UIKit
import RxSwift

protocol RxBaseViewControllerProtocol {
    associatedtype ViewModelType

    func bind(viewModel: ViewModelType)
}

class RxBaseViewController<ViewModelType>: UIViewController, RxBaseViewControllerProtocol {
    internal let disposeBag = DisposeBag()
    var viewModel: ViewModelType? {
        didSet {
            guard let viewModel = viewModel else { return }
            bind(viewModel: viewModel)
        }
    }

    // MARK: - RxBaseViewControllerProtocol
    func bind(viewModel: ViewModelType) {
        // some common routines
    }
}

class RxBaseTableViewCell<ViewModelType>: UITableViewCell, RxBaseViewControllerProtocol {
    internal var disposeBag: DisposeBag?
    var viewModel: ViewModelType? {
        didSet {
            guard let viewModel = viewModel else { return }
            bind(viewModel: viewModel)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        // Clean Rx subscriptions
        disposeBag = nil
    }

    // MARK: - RxBaseViewControllerProtocol
    func bind(viewModel: ViewModelType) {
        disposeBag = DisposeBag()

        // bind comes here
    }
}
