import Foundation
import RxSwift
import RxCocoa
import MapKit

final class RestaurantViewModel: ViewModelType {

    struct Input {
        let searchText: Variable<String>
        let doSearch: AnyObserver<Void>
        let regionAndRadius: Variable<(MKCoordinateRegion, Double)>
    }

    struct Output {
        let restaurants: Observable<[Restaurant]>
        let annotations: Observable<[RestaurantAnnotation]>
        let autocompletes: Observable<[String]>
        let networking: Variable<Bool>
        let searchTextChanged: Observable<Bool>
    }

    let input: Input
    let output: Output

    private let searchText = Variable<String>("")
    private let doSearchSubject = PublishSubject<Void>()
    private let regionAndRadius = Variable<(MKCoordinateRegion, Double)>((MKCoordinateRegion(), 0.0))

    init() {
        let yelpApiService = YelpAPIService()
        let networking = yelpApiService.networking

        let businessSearchResponse = doSearchSubject
            .withLatestFrom(Observable.combineLatest(searchText.asObservable(), regionAndRadius.asObservable()))
            .flatMapLatest { $0.0.isEmpty
                ? Observable.just(BusinessSearchResponse())
                : yelpApiService.search($0.0,
                                        latitude: $0.1.0.center.latitude,
                                        longitude: $0.1.0.center.longitude,
                                        radius: Int($0.1.1))
            }
            .share(replay: 1)

        let restaurants = businessSearchResponse
            .map { $0.businesses.map {
                Restaurant(id: $0.id, name: $0.name, rating: $0.rating,
                           distance: $0.distance, reviewCount: $0.reviewCount, price: $0.price,
                           categories: $0.categories?.compactMap { cat in cat.title },
                           location: $0.location?.displayAddress?.joined(separator: ", "),
                           imageUrl: $0.imageUrl)
                }
            }

        let annotations = businessSearchResponse
            .map { response -> [RestaurantAnnotation] in
                response.businesses.enumerated().compactMap { idx, business -> RestaurantAnnotation? in
                    guard let coordinate = business.coordinates?.clLocation2D else { return nil }
                    return RestaurantAnnotation(number: idx + 1,
                                                name: business.name,
                                                category: business.categories?.first?.title ?? "",
                                                coordinate: coordinate)
                }
            }

        let autocompleteResponse = Observable
            .combineLatest(searchText.asObservable(), regionAndRadius.asObservable())
            .debounce(0.5, scheduler: MainScheduler.instance)
            .distinctUntilChanged { $0.0 == $1.0 }
            .flatMapLatest { $0.0.isEmpty
                ? Observable.just(AutocompleteResponse())
                : yelpApiService.autocomplete($0.0,
                                              latitude: $0.1.0.center.latitude,
                                              longitude: $0.1.0.center.longitude)
            }
            .share(replay: 1)

        let autocompletes = autocompleteResponse.map { response -> [String] in
            return (response.terms?.compactMap { $0.text } ?? []) + (response.categories?.compactMap { $0.title } ?? [])
        }

        let searchTextChanged = searchText.asObservable()
            .distinctUntilChanged()
            .map { _ in true }

        self.output = Output(restaurants: restaurants,
                             annotations: annotations,
                             autocompletes: autocompletes,
                             networking: networking,
                             searchTextChanged: searchTextChanged)
        self.input = Input(searchText: searchText,
                           doSearch: doSearchSubject.asObserver(),
                           regionAndRadius: regionAndRadius)
    }
}
