import UIKit

@IBDesignable
final class MEGAVerticalButton: MEGAButton {
    override func layoutSubviews() {
        super.layoutSubviews()
        
        mnz_alignImageAndTitleVertically(padding: 0.0)
    }
}
