import Foundation

struct Location: Codable {
    let displayAddress: [String]?
    let address1: String?
    let address2: String?
    let address3: String?
    let zipCode: String
    let city: String
    let state: String
    let country: String
}
