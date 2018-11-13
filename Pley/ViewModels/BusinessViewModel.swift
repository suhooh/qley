import Foundation
import RxSwift
import RxCocoa
import MapKit

final class BusinessViewModel: ViewModelType {

    struct Input {
        let searchText: Variable<String>
        let doSearch: AnyObserver<Void>
        let regionAndRadius: Variable<(MKCoordinateRegion, Double)>
    }

    struct Output {
        let businesses: Observable<[Business]>
        let annotations: Observable<[BusinessAnnotation]>
        let autocompletes: Observable<[String]>
        let networking: Variable<Bool>
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

        let businesses = businessSearchResponse.map { $0.businesses }
        let annotations = businesses.map { businesses -> [BusinessAnnotation] in
            businesses.enumerated().compactMap { idx, business -> BusinessAnnotation? in
                guard let coordinate = business.coordinates?.clLocation2D else { return nil }
                return BusinessAnnotation(number: idx + 1,
                                          name: business.name,
                                          category: business.categories?.first?.title ?? "",
                                          coordinate: coordinate)
            }
        }

        let autocompleteResponse = Observable
            .combineLatest(searchText.asObservable(), regionAndRadius.asObservable())
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

        self.output = Output(businesses: businesses,
                             annotations: annotations,
                             autocompletes: autocompletes,
                             networking: networking)
        self.input = Input(searchText: searchText,
                           doSearch: doSearchSubject.asObserver(),
                           regionAndRadius: regionAndRadius)
    }
}
