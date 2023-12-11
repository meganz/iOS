import SwiftUI

public struct SearchAssets {
    public let placeHolder: String
    public let cancelTitle: String
    public let lightBGColor: Color
    public let darkBGColor: Color
    
    public init(
        placeHolder: String,
        cancelTitle: String,
        lightBGColor: Color,
        darkBGColor: Color
    ) {
        self.placeHolder = placeHolder
        self.cancelTitle = cancelTitle
        self.lightBGColor = lightBGColor
        self.darkBGColor = darkBGColor
    }
}
