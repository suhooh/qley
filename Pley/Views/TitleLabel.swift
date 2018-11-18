import UIKit
import QuartzCore

class TitleLabel: UILabel {

    override var text: String? {
        didSet {
            sizeToFit()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        layer.shadowRadius = 10.0
        layer.shadowOpacity = 1.0
        layer.masksToBounds = false
        layer.shouldRasterize = true
    }
}
