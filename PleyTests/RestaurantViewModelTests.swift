import XCTest
import RxCocoa
import RxSwift
import RxTest
import RxBlocking

@testable import Pley

class RestaurantViewModelTests: XCTestCase {
    var mockYelpAPIService: MockYelpAPIService!
    var viewModel: RestaurantViewModel!
    var scheduler: TestScheduler!
    var disposeBag: DisposeBag!

    override func setUp() {
        mockYelpAPIService = MockYelpAPIService()
        viewModel = RestaurantViewModel(with: mockYelpAPIService)
        scheduler = TestScheduler(initialClock: 0)
        disposeBag = DisposeBag()
    }

    override func tearDown() {
        mockYelpAPIService = nil
        viewModel = nil
        scheduler = nil
        disposeBag = nil
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

    func testSearchTermTriggersSearchTermChanged() {
        let expect = expectation(description: "SearchTermChanged")
        let observer = scheduler.createObserver(Void.self)
        let initialCall = 1
        let records: [Recorded<Event<SearchTerm>>] = [.next(10, SearchTerm("s", autocomplete: true)),
                                                      .next(20, SearchTerm("su", autocomplete: true)),
                                                      .next(30, SearchTerm("sus", autocomplete: true)),
                                                      .next(40, SearchTerm("sush", autocomplete: true)),
                                                      .next(50, SearchTerm("sushi", autocomplete: true))]
        let callCount = records.count + initialCall

        viewModel.output.searchTermChanged
            .scan(0, accumulator: { acc, _ in return acc + 1 })
            .filter { $0 == callCount }
            .subscribe(onNext: { _ in
                expect.fulfill()
            })
            .disposed(by: disposeBag)

        viewModel.output.searchTermChanged
            .subscribe(observer)
            .disposed(by: disposeBag)

        scheduler.createColdObservable(records)
            .bind(to: viewModel.input.searchTerm)
            .disposed(by: disposeBag)

        scheduler.start()

        waitForExpectations(timeout: 1.0) { error in
            XCTAssertTrue(error == nil)
            XCTAssertEqual(observer.events.count, callCount)
        }
    }

    func testSearchTermUpdatesAutocompletes() {
        let expect = expectation(description: "Autocomplete")
        let observer = scheduler.createObserver([Autocomplete].self)

        viewModel.output.autocompletes
            .subscribe(onNext: { _ in
                expect.fulfill()
            })
            .disposed(by: disposeBag)

        viewModel.output.autocompletes
            .subscribe(observer)
            .disposed(by: disposeBag)

        scheduler.createColdObservable([.next(10, SearchTerm("Sushi", autocomplete: true))])
            .bind(to: viewModel.input.searchTerm)
            .disposed(by: disposeBag)

        scheduler.start()

        let result = ["Sushi", "Sushi Delivery", "Sushi Restaurant",
                      "Sushi Bars", "Conveyor Belt Sushi", "Japanese"].compactMap { Autocomplete($0) }

        waitForExpectations(timeout: 1.0) { error in
            XCTAssertTrue(error == nil)
            XCTAssertEqual(observer.events.count, 1)
            for index in result.indices {
                // filter recent searches before comparison
                let eventValue = observer.events[0].value.element!.filter({ $0.type == .autocomplete })[index].text
                XCTAssertEqual(eventValue, result[index].text)
            }
        }
    }

    func testDoSearchUpdatesRestaurants() {
        let expect = expectation(description: "Restaurants")
        let observer = scheduler.createObserver([Restaurant].self)

        viewModel.output.restaurants
            .subscribe(onNext: { _ in
                expect.fulfill()
            })
            .disposed(by: disposeBag)

        viewModel.output.restaurants
            .subscribe(observer)
            .disposed(by: disposeBag)

        scheduler.createColdObservable([.next(10, SearchTerm("sushi", autocomplete: false))])
            .bind(to: viewModel.input.searchTerm)
            .disposed(by: disposeBag)
        scheduler.createColdObservable([.next(20, ())])
            .bind(to: viewModel.input.doSearch)
            .disposed(by: disposeBag)

        scheduler.start()

        let data = Response.businessSearchResponseJsonString.data(using: .utf8)!
        let businessSearchResponse = try? mockYelpAPIService.jsonDecoder.decode(BusinessSearchResponse.self, from: data)
        let result = businessSearchResponse!.businesses.map {
            Restaurant(id: $0.id, name: $0.name, rating: $0.rating,
                       distance: $0.distance, reviewCount: $0.reviewCount, price: $0.price,
                       categories: $0.categories?.compactMap { cat in cat.title },
                       location: $0.location?.displayAddress?.joined(separator: ", "),
                       imageUrl: $0.imageUrl, phone: $0.phone)
        }

        waitForExpectations(timeout: 1.0) { error in
            XCTAssertTrue(error == nil)
            XCTAssertEqual(observer.events.count, 1)
            XCTAssertEqual(observer.events[0].value.element![0].id, result[0].id)
        }
    }

    func xtestDoSearchUpdatesAnnotations() {
        let expect = expectation(description: "Annotations")
        let observer = scheduler.createObserver([RestaurantAnnotation].self)

        viewModel.output.annotations.asObservable()
            .subscribe(onNext: { _ in
                expect.fulfill()
            })
            .disposed(by: disposeBag)

        viewModel.output.annotations.asObservable()
            .subscribe(observer)
            .disposed(by: disposeBag)

        scheduler.createColdObservable([.next(10, SearchTerm("sushi", autocomplete: false))])
            .bind(to: viewModel.input.searchTerm)
            .disposed(by: disposeBag)
        scheduler.createColdObservable([.next(20, ())])
            .bind(to: viewModel.input.doSearch)
            .disposed(by: disposeBag)

        scheduler.start()

        let data = Response.businessSearchResponseJsonString.data(using: .utf8)!
        let businessSearchResponse = try? mockYelpAPIService.jsonDecoder.decode(BusinessSearchResponse.self, from: data)
        let result = businessSearchResponse!.businesses
            .enumerated().compactMap { idx, business -> RestaurantAnnotation? in
                guard let coordinate = business.coordinates?.clLocation2D else { return nil }
                return RestaurantAnnotation(id: business.id,
                                            number: idx + 1,
                                            name: business.name,
                                            category: business.categories?.first?.title ?? "",
                                            coordinate: coordinate)
        }

        waitForExpectations(timeout: 1.0) { error in
            XCTAssertTrue(error == nil)
            XCTAssertEqual(observer.events.count, 1)
            XCTAssertEqual(observer.events[0].value.element![0].name, result[0].name)
        }
    }
}
