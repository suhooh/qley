import Foundation
import RxSwift
import RxAlamofire
import Alamofire
import SwiftyJSON

@testable import Pley

class MockYelpAPIService: YelpAPIServiceProtocol {

    var isNetworking = Variable<Bool>(false)

    func search(_ term: String,
                latitude: Double, longitude: Double, radius: Int) -> Observable<BusinessSearchResponse> {

        isNetworking.value = true
        isNetworking.value = false

        let json = JSON(parseJSON: Response.businessSearchResponseJson)
        guard let businessSearchResponse = BusinessSearchResponse(json) else {
            return Observable.just(BusinessSearchResponse())
        }
        return Observable.just(businessSearchResponse)
    }

    func autocomplete(_ term: String, latitude: Double?, longitude: Double?) -> Observable<AutocompleteResponse> {
        let json = JSON(parseJSON: Response.autocompleteResponseJsonString)
        guard let autocompleteResponse = AutocompleteResponse(json) else {
            return Observable.just(AutocompleteResponse())
        }
        return Observable.just(autocompleteResponse)
    }
}
