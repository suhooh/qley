import Foundation
import RxSwift
import RxCocoa
import MapKit

final class RestaurantViewModel: ViewModelType {

    struct Input {
        let searchTerm: Variable<SearchTerm>
        let searchArea: Variable<SearchArea>
        let doSearch: AnyObserver<Void>
    }

    struct Output {
        let restaurants: Observable<[Restaurant]>
        let annotations: Observable<[RestaurantAnnotation]>
        let autocompletes: Observable<[String]>
        let networking: Variable<Bool>
        let searchTermChanged: Observable<Void>
    }

    let input: Input
    let output: Output

    private let searchTerm = Variable<SearchTerm>(SearchTerm())
    private let searchArea = Variable<SearchArea>(SearchArea())
    private let doSearchSubject = PublishSubject<Void>()

    init() {
        let yelpApiService = YelpAPIService()
        let networking = yelpApiService.networking

        let businessSearchResponse = doSearchSubject
            .withLatestFrom(Observable.combineLatest(searchTerm.asObservable(), searchArea.asObservable()))
            .flatMapLatest { term, area -> Observable<BusinessSearchResponse> in
                return term.isEmpty
                    ? Observable.just(BusinessSearchResponse())
                    : yelpApiService.search(term.value,
                                            latitude: area.latitude,
                                            longitude: area.longitude,
                                            radius: Int(area.radius))
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
            .combineLatest(searchTerm.asObservable(), searchArea.asObservable())
            .filter { term, _ -> Bool in return term.needsAutocomplete }
            .debounce(0.3, scheduler: MainScheduler.instance)
            .distinctUntilChanged { arg0, arg1 -> Bool in
                let (term1, _) = arg0
                let (term2, _) = arg1
                return term1 == term2
            }
            .flatMapLatest { term, area -> Observable<AutocompleteResponse> in
                return term.isEmpty
                    ? Observable.just(AutocompleteResponse())
                    : yelpApiService.autocomplete(term.value,
                                                  latitude: area.latitude,
                                                  longitude: area.longitude)
            }
            .share(replay: 1)

        let autocompletes = autocompleteResponse.map { response -> [String] in
            return (response.terms?.compactMap { $0.text } ?? []) + (response.categories?.compactMap { $0.title } ?? [])
        }

        let searchTermChanged = searchTerm.asObservable()
            .distinctUntilChanged()
            .map { _ in }

        self.output = Output(restaurants: restaurants,
                             annotations: annotations,
                             autocompletes: autocompletes,
                             networking: networking,
                             searchTermChanged: searchTermChanged)
        self.input = Input(searchTerm: searchTerm,
                           searchArea: searchArea,
                           doSearch: doSearchSubject.asObserver())
    }
}
