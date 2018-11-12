import Foundation
import RxSwift
import RxCocoa
import MapKit

final class BusinessViewModel: ViewModelType {

    struct Input {
        let searchText: Variable<String>
        let doSearch: AnyObserver<Void>
    }

    struct Output {
        let businesses: Observable<[Business]>
        let annotations: Observable<[BusinessAnnotation]>
        let autocompletes: Observable<[String]>
    }

    let input: Input
    let output: Output

    private let searchText = Variable<String>("")
    private let doSearchSubject = PublishSubject<Void>()



    // TODO: live location
    let location = CLLocation(latitude: 21.282778, longitude: -157.829444)
    private let regionRadius: CLLocationDistance = 1000
    let coordinateRegion = Variable<MKCoordinateRegion>(MKCoordinateRegion(center: CLLocation(latitude: 21.282778, longitude: -157.829444).coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000))



    init() {
        let yelpApiService = YelpAPIService()

        let businessSearchResponse = doSearchSubject
            .withLatestFrom(searchText.asObservable())
            .flatMapLatest { $0.isEmpty ? Observable.empty() : yelpApiService.search($0, latitude: 21.282778, longitude: -157.829444) }
            .share(replay: 1)

        let businesses = businessSearchResponse.map { $0.businesses }
        let annotations = businesses.map { businesses -> [BusinessAnnotation] in
            businesses.compactMap { business -> BusinessAnnotation? in
                guard let coordinate = business.coordinates?.clLocation2D else { return nil }
                return BusinessAnnotation(name: business.name, coordinate: coordinate)
            }
        }

        let autocompleteResponse = searchText.asObservable()
            .distinctUntilChanged()
            .flatMapLatest { $0.isEmpty ? Observable.empty() : yelpApiService.autocomplete($0, latitude: 21.282778, longitude: -157.829444) }
            .share(replay: 1)

        let autocompletes = autocompleteResponse.map { response -> [String] in
            return (response.terms?.compactMap { $0.text } ?? []) + (response.categories?.compactMap { $0.title } ?? [])
        }

        self.output = Output(businesses: businesses, annotations: annotations, autocompletes: autocompletes)
        self.input = Input(searchText: searchText, doSearch: doSearchSubject.asObserver())
    }
}
