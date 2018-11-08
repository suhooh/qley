import Foundation
import SwiftyJSON

struct Category {
    let title: String
    let alias: String

    init?(_ json: JSON) {
        guard
            let title = json["title"].string,
            let alias = json["alias"].string
            else {
                return nil
        }

        self.title = title
        self.alias = alias
    }
}
