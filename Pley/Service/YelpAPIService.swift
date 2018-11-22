import UIKit
import RxSwift
import RxAlamofire
import Alamofire

class YelpAPIService: YelpAPIServiceProtocol {

    struct Constants {
        static let host = "api.yelp.com"
        fileprivate static let baseURL = "https://" + host + "/v3/"
        private static let APIKeyPrefix = "Bearer "
        // swiftlint:disable line_length
        fileprivate static let APIKey =  APIKeyPrefix // + "YOUR API KEY HERE"
        // swiftlint:enable line_length
    }

    enum Resource: String {
        case businessSearch = "businesses/search"
        case autocomplete = "autocomplete"

        var path: String { return Constants.baseURL + rawValue }
    }

    enum APIError: Error {
        case parseFailed
    }

    var isNetworking = Variable<Bool>(false)
    var jsonDecoder: JSONDecoder = {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        return jsonDecoder
    }()

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

        isNetworking.value = true
        return RxAlamofire.requestData(.get, Resource.businessSearch.path,
                                       parameters: params,
                                       encoding: URLEncoding.default,
                                       headers: headers
            )
            .flatMap { [weak self] (_, data) -> Observable<BusinessSearchResponse> in
                self?.isNetworking.value = false
                guard let decoded = try? self?.jsonDecoder.decode(BusinessSearchResponse.self, from: data),
                    let businessSearchResponse = decoded
                    else {
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

        return RxAlamofire.requestData(.get, Resource.autocomplete.path,
                                       parameters: params,
                                       encoding: URLEncoding.default,
                                       headers: headers
            )
            .flatMap { [weak self] (_, data) -> Observable<AutocompleteResponse> in
                guard let decoded = try? self?.jsonDecoder.decode(AutocompleteResponse.self, from: data),
                    let autocompleteResponse = decoded
                    else {
                        return Observable.error(APIError.parseFailed)
                }
                return Observable.just(autocompleteResponse)
        }
    }
}
