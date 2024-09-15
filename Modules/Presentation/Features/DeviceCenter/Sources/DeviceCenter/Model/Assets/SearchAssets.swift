import SwiftUI

public struct SearchAssets {
    public let placeHolder: String
    public let cancelTitle: String
    public let backgroundColor: Color
    
    public init(
        placeHolder: String,
        cancelTitle: String,
        backgroundColor: Color
    ) {
        self.placeHolder = placeHolder
        self.cancelTitle = cancelTitle
        self.backgroundColor = backgroundColor
    }
}
