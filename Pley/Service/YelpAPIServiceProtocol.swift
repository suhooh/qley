import Foundation
import RxSwift

protocol YelpAPIServiceProtocol: class {
    var isNetworking: Variable<Bool> { get set }
    func search(_ term: String, latitude: Double, longitude: Double, radius: Int) -> Observable<BusinessSearchResponse>
    func autocomplete(_ term: String, latitude: Double?, longitude: Double?) -> Observable<AutocompleteResponse>
}
