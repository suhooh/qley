import Foundation
import RxSwift
import RxAlamofire
import Alamofire
import SwiftyJSON

@testable import Pley

class MockYelpAPIService: YelpAPIServiceProtocol {

    var networking = Variable<Bool>(false)

    func search(_ term: String,
                latitude: Double, longitude: Double, radius: Int) -> Observable<BusinessSearchResponse> {
        let searchTerm = term.trimmingCharacters(in: .whitespacesAndNewlines)
            .addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""

        networking.value = true
        networking.value = false

        return Observable.just(BusinessSearchResponse())
    }

    func autocomplete(_ term: String, latitude: Double?, longitude: Double?) -> Observable<AutocompleteResponse> {
        let searchTerm = term.trimmingCharacters(in: .whitespacesAndNewlines)
            .addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""

        return searchTerm.isEmpty ? Observable.just(AutocompleteResponse()) : Observable.just(AutocompleteResponse())
    }
}
