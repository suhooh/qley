import Foundation
import RxSwift
import MapKit

final class BusinessViewModel {

    private let yelpApiService: YelpAPIService
    private let disposeBag = DisposeBag()

    let searchText = Variable<String>("")
    private let autocompleteResponse: Observable<AutocompleteResponse>
    let autocompletes: Observable<[String]>

    private let businessSearchResponse: Observable<BusinessSearchResponse>
    let businesses: Observable<[Business]>
    let annotations: Observable<[BusinessAnnotation]>

    // TODO: live location
    let location = CLLocation(latitude: 21.282778, longitude: -157.829444)
    private let regionRadius: CLLocationDistance = 1000
    let coordinateRegion = Variable<MKCoordinateRegion>(MKCoordinateRegion(center: CLLocation(latitude: 21.282778, longitude: -157.829444).coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000))

    init(_ yelpApiService: YelpAPIService = YelpAPIService()) {
        self.yelpApiService = yelpApiService

        autocompleteResponse = searchText.asObservable()
            .distinctUntilChanged()
            .flatMapLatest { $0.isEmpty ? Observable.empty() : yelpApiService.autocomplete($0, latitude: 21.282778, longitude: -157.829444) }
            .share(replay: 1)

        autocompletes = autocompleteResponse.map { response -> [String] in
            return (response.terms?.compactMap { $0.text } ?? []) + (response.categories?.compactMap { $0.title } ?? [])
        }

        businessSearchResponse = searchText.asObservable()
            .debounce(0.3, scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .flatMapLatest { $0.isEmpty ? Observable.empty() : yelpApiService.search($0, latitude: 21.282778, longitude: -157.829444) }
            .share(replay: 1)

        businesses = businessSearchResponse.map { $0.businesses }
        annotations = businesses.map { businesses -> [BusinessAnnotation] in
            businesses.compactMap { business -> BusinessAnnotation? in
                guard let coordinate = business.coordinates?.clLocation2D else { return nil }
                return BusinessAnnotation(name: business.name, coordinate: coordinate)
            }
        }
    }
}
