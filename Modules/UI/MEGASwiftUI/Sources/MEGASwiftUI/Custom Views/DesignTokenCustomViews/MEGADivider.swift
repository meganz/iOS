import MEGADesignToken
import SwiftUI

public struct MEGADivider: View {
    let isDesignTokenEnabled: Bool
    let backgroundColor: Color?
    
    public init(isDesignTokenEnabled: Bool, backgroundColor: Color? = nil) {
        self.isDesignTokenEnabled = isDesignTokenEnabled
        self.backgroundColor = backgroundColor
    }
    public var body: some View {
        divider()
    }
    
    @ViewBuilder
    func divider() -> some View {
        if isDesignTokenEnabled {
            Divider().background(TokenColors.Background.page.swiftUI)
        } else if let backgroundColor {
            Divider().background(backgroundColor)
        } else {
            Divider()
        }
    }
}
