import Foundation
import RxSwift

final class BusinessViewModel {

    private let yelpApiService: YelpAPIService
    private let disposeBag = DisposeBag()

    private let businessSearchResponse: Observable<BusinessSearchResponse>
    let businesses: Observable<[Business]>
    let searchText = Variable<String>("")

    init(_ yelpApiService: YelpAPIService = YelpAPIService()) {
        self.yelpApiService = yelpApiService

        businessSearchResponse = searchText.asObservable()
            .debounce(0.3, scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .flatMapLatest { $0.isEmpty ? Observable.empty() : yelpApiService.search($0) }
            .share(replay: 1)

        businesses = businessSearchResponse.map { $0.businesses }
    }
}
