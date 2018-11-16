import Foundation

struct SearchTerm: Equatable {
    let value: String
    let needsAutocomplete: Bool

    var isEmpty: Bool { return value.isEmpty }

    init(_ value: String = "", autocomplete: Bool = false) {
        self.value = value
        self.needsAutocomplete = autocomplete
    }

    public static func == (lhs: SearchTerm, rhs: SearchTerm) -> Bool {
        return lhs.value == rhs.value
    }
}
