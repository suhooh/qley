import Foundation

enum AutocompleteType {
    case autocomplete
    case recentSearch
}

struct Autocomplete {
    let text: String
    let type: AutocompleteType

    init?(_ text: String?, type: AutocompleteType = .autocomplete) {
        guard let text = text else { return nil }
        self.text = text
        self.type = type
    }
}
