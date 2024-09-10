import MEGADesignToken
import SwiftUI

public struct MEGADivider: View {
    public init() {}
    
    public var body: some View {
        divider()
    }
    
    @ViewBuilder
    func divider() -> some View {
        Divider().background(TokenColors.Background.page.swiftUI)
    }
}
