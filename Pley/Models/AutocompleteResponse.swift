import Foundation
import SwiftyJSON

struct AutocompleteResponse {
    let terms: [Term]?
    let businesses: [Business]?
    let categories: [Category]?

    init() {
        terms = nil
        businesses = nil
        categories = nil
    }

    init?(_ json: JSON) {
        self.terms = json["terms"].array?.compactMap(Term.init)
        self.businesses = json["businesses"].array?.compactMap(Business.init)
        self.categories = json["categories"].array?.compactMap(Category.init)
    }
}
