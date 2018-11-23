import Foundation

struct BusinessSearchResponse: Codable {
    let total: Int
    let businesses: [Business]
    let region: Region?

    init() {
        total = 0
        businesses = []
        region = nil
    }
}
