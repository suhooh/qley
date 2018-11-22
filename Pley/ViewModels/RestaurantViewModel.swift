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
        let autocompletes: Observable<[Autocomplete]>
        let annotations: Driver<[RestaurantAnnotation]>
        let searchTermChanged: Observable<Void>
        let isNetworking: Variable<Bool>
    }

    let input: Input
    let output: Output

    private let searchTerm = Variable<SearchTerm>(SearchTerm())
    private let searchArea = Variable<SearchArea>(SearchArea())
    private let doSearchSubject = PublishSubject<Void>()

    init(with yelpApiService: YelpAPIServiceProtocol = YelpAPIService()) {

        let businessSearchResponse = doSearchSubject
            .withLatestFrom(Observable.combineLatest(searchTerm.asObservable(), searchArea.asObservable()))
            .do(onNext: { term, _ in
                RecentSearch.save(term.value)
            })
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
                           imageUrl: $0.imageUrl, phone: $0.phone)
                }
            }

        let annotations = businessSearchResponse
            .map { response -> [RestaurantAnnotation] in
                response.businesses.enumerated().compactMap { idx, business -> RestaurantAnnotation? in
                    guard let coordinate = business.coordinates?.clLocation2D else { return nil }
                    return RestaurantAnnotation(id: business.id,
                                                number: idx + 1,
                                                name: business.name,
                                                category: business.categories?.first?.title ?? "",
                                                coordinate: coordinate)
                }
            }
            .asDriver(onErrorJustReturn: [])

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

        let autocompletes = Observable
            .combineLatest(autocompleteResponse, searchTerm.asObservable())
            .map { response, term -> [Autocomplete] in
                let recentSearches = RecentSearch.load(term.value).compactMap { Autocomplete($0, type: .recentSearch) }
                let terms = response.terms?.compactMap { Autocomplete($0.text, type: .autocomplete) } ?? []
                let categories = response.categories?.compactMap { Autocomplete($0.title, type: .autocomplete) } ?? []
                let autocompletes = (terms + categories).filter { autocomplete -> Bool in
                    return !recentSearches.map { $0.text }.contains(autocomplete.text)
                }
                return recentSearches + autocompletes
        }

        let searchTermChanged = searchTerm.asObservable()
            .distinctUntilChanged()
            .map { _ in }

        self.output = Output(restaurants: restaurants,
                             autocompletes: autocompletes,
                             annotations: annotations,
                             searchTermChanged: searchTermChanged,
                             isNetworking: yelpApiService.isNetworking)
        self.input = Input(searchTerm: searchTerm,
                           searchArea: searchArea,
                           doSearch: doSearchSubject.asObserver())
    }
}

private struct RecentSearch {
    private static let keyForRecentSearch = "RecentSearch"
    private static let maxRecentSearchCount = 5

    static func load(_ substring: String? = nil) -> [String] {
        var recentSearch: [String] = []
        if let saved = UserDefaults.standard.array(forKey: keyForRecentSearch) as? [String] {
            recentSearch += saved
        }
        if let substring = substring, !substring.isEmpty {
            recentSearch = recentSearch.filter {
                $0.lowercased().range(of: substring.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()) != nil
            }
        }
        return recentSearch
    }

    static func save(_ text: String?) {
        guard let text = text, !text.isEmpty else { return }

        var recentSearch = load()
        if let index = recentSearch.firstIndex(of: text) {
            recentSearch.remove(at: index)
        }
        recentSearch.insert(text, at: 0)
        recentSearch = Array(recentSearch[0..<min(recentSearch.count, RecentSearch.maxRecentSearchCount)])

        let userDefaults = UserDefaults.standard
        userDefaults.set(recentSearch, forKey: keyForRecentSearch)
        userDefaults.synchronize()
    }
}
