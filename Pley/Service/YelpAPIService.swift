import UIKit
import RxSwift
import RxAlamofire
import Alamofire
import SwiftyJSON

class YelpAPIService {
    private struct Constants {
        static let baseURL = "https://api.yelp.com/v3/"
        static let APIKey = "// TODO: add api key"
    }

    enum Resource: String {
        case BusinessSearch = "businesses/search"

        var path: String { return Constants.baseURL + rawValue }
    }

    enum APIError: Error {
        case parseFailed
    }

    func search(_ term: String, latitude: Double, longitude: Double) -> Observable<BusinessSearchResponse> {
        let headers = ["Authorization": Constants.APIKey]
        let params = [
            "term": term.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "",
            "latitude": String(latitude),
            "longitude" : String(longitude)
        ]

        return RxAlamofire.requestJSON(.get, Resource.BusinessSearch.path, parameters: params, encoding: URLEncoding.default, headers: headers)
            .flatMap { (_, json) -> Observable<BusinessSearchResponse> in
                guard let businessSearchResponse = BusinessSearchResponse(JSON(json)) else { return Observable.error(APIError.parseFailed) }
                return Observable.just(businessSearchResponse)
            }
    }
}
