import Foundation

struct AutocompleteResponse: Codable {
    let terms: [Term]?
    let businesses: [Business]?
    let categories: [Category]?

    init() {
        terms = nil
        businesses = nil
        categories = nil
    }
}
