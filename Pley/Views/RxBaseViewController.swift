import UIKit
import RxSwift

protocol RxBaseViewControllerProtocol: class {
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
        // common routines
    }
}

class RxBaseTableViewCell<ViewModelType>: UITableViewCell, RxBaseViewControllerProtocol {
    internal var disposeBag = DisposeBag()
    var viewModel: ViewModelType? {
        didSet {
            guard let viewModel = viewModel else { return }
            bind(viewModel: viewModel)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        // Clean Rx subscriptions by creating a new bag
        disposeBag = DisposeBag()
    }

// MARK: - RxBaseViewControllerProtocol
    func bind(viewModel: ViewModelType) {
        // bind comes here
    }
}
