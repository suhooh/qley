import UIKit
import RxSwift
import RxAlamofire
import Alamofire
import SwiftyJSON

class YelpAPIService {
    struct Constants {
        static let host = "api.yelp.com"
        fileprivate static let baseURL = "https://" + host + "/v3/"
        private static let APIKeyPrefix = "Bearer "
        fileprivate static let APIKey =  APIKeyPrefix // + "YOUR API KEY HERE"
    }

    enum Resource: String {
        case businessSearch = "businesses/search"
        case autocomplete = "autocomplete"

        var path: String { return Constants.baseURL + rawValue }
    }

    enum APIError: Error {
        case parseFailed
    }

    let networking = Variable<Bool>(false)

    func search(_ term: String,
                latitude: Double, longitude: Double, radius: Int) -> Observable<BusinessSearchResponse> {
        let searchTerm = term.trimmingCharacters(in: .whitespacesAndNewlines)
            .addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""

        let headers = ["Authorization": Constants.APIKey]
        let params = [
            "term": searchTerm,
            "latitude": String(latitude),
            "longitude": String(longitude),
            "radius": String(min(radius, 40000))
        ]

        networking.value = true
        return RxAlamofire.requestJSON(.get, Resource.businessSearch.path,
                                       parameters: params,
                                       encoding: URLEncoding.default,
                                       headers: headers
            )
            .flatMap { (_, json) -> Observable<BusinessSearchResponse> in
                self.networking.value = false
                guard let businessSearchResponse = BusinessSearchResponse(JSON(json)) else {
                    return Observable.error(APIError.parseFailed)
                }
                return Observable.just(businessSearchResponse)
            }
    }

    func autocomplete(_ term: String, latitude: Double?, longitude: Double?) -> Observable<AutocompleteResponse> {
        let searchTerm = term.trimmingCharacters(in: .whitespacesAndNewlines)
            .addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""

        let headers = ["Authorization": Constants.APIKey]
        var params = [ "text": searchTerm ]
        if let latitude = latitude { params["latitude"] = String(latitude) }
        if let longitude = longitude { params["longitude"] = String(longitude) }

        return RxAlamofire.requestJSON(.get, Resource.autocomplete.path,
                                       parameters: params,
                                       encoding: URLEncoding.default,
                                       headers: headers
            )
            .flatMap { (_, json) -> Observable<AutocompleteResponse> in
                guard let autocompleteResponse = AutocompleteResponse(JSON(json)) else {
                    return Observable.error(APIError.parseFailed)
                }
                return Observable.just(autocompleteResponse)
        }
    }
}
