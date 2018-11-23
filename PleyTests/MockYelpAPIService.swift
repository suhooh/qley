import Foundation
import RxSwift
import RxAlamofire
import Alamofire

@testable import Pley

class MockYelpAPIService: YelpAPIServiceProtocol {
    var jsonDecoder: JSONDecoder = {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        return jsonDecoder
    }()

    var isNetworking = Variable<Bool>(false)

    func search(_ term: String,
                latitude: Double, longitude: Double, radius: Int) -> Observable<BusinessSearchResponse> {

        isNetworking.value = true
        isNetworking.value = false

        guard let data = Response.businessSearchResponseJsonString.data(using: .utf8),
            let businessSearchResponse = try? self.jsonDecoder.decode(BusinessSearchResponse.self, from: data)
            else {
                return Observable.just(BusinessSearchResponse())
        }
        return Observable.just(businessSearchResponse)
    }

    func autocomplete(_ term: String, latitude: Double?, longitude: Double?) -> Observable<AutocompleteResponse> {
        guard let data = Response.autocompleteResponseJsonString.data(using: .utf8),
            let autocompleteResponse = try? self.jsonDecoder.decode(AutocompleteResponse.self, from: data)
            else {
                return Observable.just(AutocompleteResponse())
        }
        return Observable.just(autocompleteResponse)
    }
}
