import Foundation
import SwiftyJSON

struct Term {
    let text: String?

    init?(_ json: JSON) {
        self.text = json["text"].string
    }
}
