import UIKit
import MEGAUI

public extension UIButton {

    /// Will set background color with given color. What is under the hood is generating an 1 by 1 pixel image filled with given color,
    /// and set to `backGroundImage` so that button could have different color of background based on the state - (normal, highlighted, etc).
    /// - Parameters:
    ///   - color: The `UIColor` to fill to the button's background.
    ///   - state: `UIButton`'s state. See, `UIControl.State`.
    func setBackgroundColorImage(_ color: UIColor, for state: UIControl.State) {
        let smallestWidthForImageByPoint = 1
        let smallestHeightForImageByPoint = 1
        self.setBackgroundImage(
            color.image(withSize:
                CGSize(
                    width: smallestWidthForImageByPoint,
                    height: smallestHeightForImageByPoint
                )
            ),
            for: state
        )
    }
}
