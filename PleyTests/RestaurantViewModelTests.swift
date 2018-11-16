import XCTest
import RxCocoa
import RxSwift
import RxTest
import RxBlocking

@testable import Pley

class RestaurantViewModelTests: XCTestCase {
    var viewModel: RestaurantViewModel!
    var scheduler: TestScheduler!
    var disposeBag: DisposeBag!

    override func setUp() {
        viewModel = RestaurantViewModel(with: MockYelpAPIService())
        scheduler = TestScheduler(initialClock: 0)
        disposeBag = DisposeBag()
    }

    func testSearchTermStartsAsEmpty() throws {
        guard let searchTerm = try viewModel.input.searchTerm.asObservable().toBlocking().first() else {
            return XCTFail("Search term is nil")
        }
        XCTAssertEqual(searchTerm.isEmpty, true)
        XCTAssertEqual(searchTerm.needsAutocomplete, false)
    }

    func testSearchAreaStartsAsEmpty() throws {
        guard let searchArea = try viewModel.input.searchArea.asObservable().toBlocking().first() else {
            return XCTFail("Search area is nil")
        }
        XCTAssertEqual(searchArea.latitude, 0)
        XCTAssertEqual(searchArea.latitude, 0)
        XCTAssertEqual(searchArea.radius, 0)
    }
}
